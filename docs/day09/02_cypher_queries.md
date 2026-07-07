# Cypher Query Patterns — Fraud Detection

**Day 9 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 7 July 2026

> 5 Cypher query patterns covering the core fraud detection use cases.
> Each query includes: purpose, sample input, expected output, and
> which graph analysis algorithm it uses.
> All real-time path queries run on the primary Neo4j instance.
> Analytical queries (community detection, PageRank) run on the READ REPLICA
> to avoid blocking real-time lookups.

---

## Query 1: Shortest Path to Known Fraud Account

**Purpose:** Determine how many hops a card is from a confirmed fraud account.
A card 2 hops away (e.g. shared a device with an account that transacted with
a known fraud merchant) carries far higher risk than one 6 hops away.

**Algorithm:** Dijkstra / BFS shortest path
**Runs on:** Primary (real-time, must complete in <20ms)

```cypher
// Input: card_hash of the transaction being evaluated
// Output: minimum hop count to any confirmed-fraud card, path details

MATCH path = shortestPath(
  (c:Card {card_hash: $card_hash})-[*1..6]-(fraud:Card {is_blocked: true})
)
WHERE ALL(r IN relationships(path) WHERE
  type(r) IN ['SHARED_DEVICE','SHARED_ADDRESS','USED_IP',
              'REGISTERED_PHONE','TRANSACTED_WITH','SAME_BENEFICIARY']
)
RETURN
  length(path)            AS hops_to_fraud,
  [node IN nodes(path) | labels(node)[0] + ':' + coalesce(node.card_hash, node.device_fingerprint, node.ip_hash, node.merchant_id, '?')]
                          AS path_entities,
  [rel IN relationships(path) | type(rel)]
                          AS relationship_types
ORDER BY hops_to_fraud ASC
LIMIT 1

// Sample input:  {card_hash: "a3f8c2d1e4b5..."}
// Expected output if fraud ring connected:
//   hops_to_fraud: 2
//   path_entities: ["Card:a3f8c2d1...", "Device:fp_abc123...", "Card:blocked_xyz..."]
//   relationship_types: ["SHARED_DEVICE", "SHARED_DEVICE"]
//
// Expected output if no fraud connection within 6 hops:
//   (no rows returned — handled as hops_to_known_fraud = -1 in GraphSignals)
```

---

## Query 2: Community Detection — Suspicious Cluster Identification

**Purpose:** Find clusters of densely connected cards, devices, and addresses
that are weakly connected to the rest of the graph. A dense community that
shares multiple devices and addresses but has few connections outside itself
is a classic synthetic identity fraud ring signature.

**Algorithm:** Louvain Community Detection (Neo4j GDS library)
**Runs on:** READ REPLICA (analytical — may take seconds, must not block primary)

```cypher
// Step 1: Project a graph of Cards and Devices connected by SHARED_DEVICE
CALL gds.graph.project(
  'card-device-graph',
  ['Card', 'Device'],
  {SHARED_DEVICE: {orientation: 'UNDIRECTED'}}
)

// Step 2: Run Louvain community detection
CALL gds.louvain.stream('card-device-graph', {
  maxIterations: 10,
  tolerance: 0.0001
})
YIELD nodeId, communityId

// Step 3: Find communities above suspicion threshold
WITH communityId, collect(gds.util.asNode(nodeId)) AS members
WHERE size(members) >= 5  // community of 5+ entities is worth examining

// Step 4: Score the community — how dense vs isolated?
WITH communityId, members,
     size([m IN members WHERE 'Card' IN labels(m)]) AS card_count,
     size([m IN members WHERE 'Device' IN labels(m)]) AS device_count

// Flag communities where device sharing is abnormally high
// (normal: 1-2 cards per device; suspicious: 5+ cards sharing same device)
WHERE (card_count * 1.0 / device_count) > 4

RETURN
  communityId,
  card_count,
  device_count,
  round(card_count * 1.0 / device_count, 2) AS cards_per_device_ratio,
  [m IN members WHERE 'Card' IN labels(m) | m.card_hash] AS card_hashes
ORDER BY cards_per_device_ratio DESC
LIMIT 20

// Sample input: none (runs on full graph)
// Expected output for a synthetic identity ring:
//   communityId: 4821
//   card_count: 47
//   device_count: 3
//   cards_per_device_ratio: 15.67
//   card_hashes: ["hash_001", "hash_002", ... 47 items]
// → 47 cards sharing 3 devices is a clear fraud ring signature
```

---

## Query 3: Centrality — Shared Infrastructure Node Detection

**Purpose:** Find devices or IP addresses with abnormally high PageRank.
A device with high centrality that connects many otherwise unrelated accounts
is likely shared fraud infrastructure (e.g. a device farm used to open many
synthetic identity accounts).

**Algorithm:** PageRank (Neo4j GDS)
**Runs on:** READ REPLICA

```cypher
// Project graph of all entity types connected by any relationship
CALL gds.graph.project(
  'full-entity-graph',
  ['Card', 'Device', 'IPAddress', 'PhoneNumber', 'Email', 'PhysicalAddress'],
  {
    SHARED_DEVICE:   {orientation: 'UNDIRECTED'},
    USED_IP:         {orientation: 'UNDIRECTED'},
    REGISTERED_PHONE:{orientation: 'UNDIRECTED'},
    REGISTERED_EMAIL:{orientation: 'UNDIRECTED'},
    SHARED_ADDRESS:  {orientation: 'UNDIRECTED'}
  }
)

// Run PageRank
CALL gds.pageRank.stream('full-entity-graph', {
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeId, score

WITH gds.util.asNode(nodeId) AS entity, score
WHERE score > 5.0  // high centrality threshold — tuned empirically
  AND NOT 'Card' IN labels(entity)  // cards can legitimately have high centrality; infrastructure nodes cannot

RETURN
  labels(entity)[0]   AS entity_type,
  coalesce(
    entity.device_fingerprint,
    entity.ip_hash,
    entity.phone_hash,
    entity.email_hash,
    entity.address_hash
  )                   AS entity_id,
  round(score, 3)     AS pagerank_score
ORDER BY pagerank_score DESC
LIMIT 50

// Sample output for shared device farm:
//   entity_type: "Device"
//   entity_id: "fp_device_farm_001"
//   pagerank_score: 23.847
// → A device with PageRank 23 connects 23x more accounts than an average device
// → Flagged as potential device farm / shared fraud infrastructure
```

---

## Query 4: Temporal Connection Growth — Account Farming Detection

**Purpose:** Identify entities gaining new connections abnormally fast.
A card that gains 15 new device connections in 7 days is likely being used
to register synthetic identities rapidly ("account farming").

**Algorithm:** Time-windowed relationship count
**Runs on:** Primary (indexed timestamp — fast)

```cypher
// Input: configurable window (default 7 days) and threshold (default 10 new connections)
// Find all cards with rapid new-connection growth in the last N days

MATCH (c:Card)-[r]-(entity)
WHERE r.first_shared_at >= datetime() - duration({days: $window_days})
  AND type(r) IN ['SHARED_DEVICE', 'SHARED_ADDRESS', 'REGISTERED_PHONE',
                  'REGISTERED_EMAIL', 'USED_IP']

WITH c, count(DISTINCT entity) AS new_connections_in_window,
     collect(DISTINCT {type: labels(entity)[0], id: coalesce(entity.device_fingerprint, entity.ip_hash, entity.phone_hash, entity.email_hash, entity.address_hash)}) AS new_entities

WHERE new_connections_in_window > $threshold  // default: 10

RETURN
  c.card_hash              AS card_hash,
  new_connections_in_window,
  new_entities
ORDER BY new_connections_in_window DESC
LIMIT 100

// Sample input:  {window_days: 7, threshold: 10}
// Expected output for account farming:
//   card_hash: "a3f8c2d1..."
//   new_connections_in_window: 18
//   new_entities: [
//     {type: "Device", id: "fp_001"},
//     {type: "Device", id: "fp_002"},
//     ... 18 items
//   ]
// → 18 new entity connections in 7 days is 6× the normal rate
// → Flagged as potential account farming activity
```

---

## Query 5: Subgraph Matching — Known Fraud Topology Detection

**Purpose:** Match known fraud topologies (templates) against the live graph.
If a transaction matches the exact structural pattern of a previously confirmed
fraud ring, it should be treated as very high risk even before rules or ML fire.

**Topology: Triangulation Fraud**
Card A and Card B share a Device D. Card A transacts with Merchant M.
Merchant M ships to Address X. Address X also receives shipments from
Merchant M paid by Card B. → Classic triangulation fraud ring.

**Runs on:** Primary (indexed lookups — pattern matching on small subgraph)

```cypher
// Input: card_hash of the transaction being evaluated
// Match the triangulation fraud topology centred on this card

MATCH (cardA:Card {card_hash: $card_hash})
MATCH (cardA)-[:SHARED_DEVICE]-(device:Device)-[:SHARED_DEVICE]-(cardB:Card)
WHERE cardA <> cardB

MATCH (cardA)-[:TRANSACTED_WITH]->(merchant:Merchant)
MATCH (cardB)-[:TRANSACTED_WITH]->(merchant)

MATCH (merchant)-[:SHIPS_TO]->(address:PhysicalAddress)
MATCH (cardA)-[:SHARED_ADDRESS]-(address)
MATCH (cardB)-[:SHARED_ADDRESS]-(address)

RETURN
  cardA.card_hash          AS evaluated_card,
  cardB.card_hash          AS connected_card,
  device.device_fingerprint AS shared_device,
  merchant.merchant_id     AS shared_merchant,
  address.address_hash     AS shared_address,
  'TRIANGULATION_FRAUD_V1' AS topology_matched

// Sample output when topology matches:
//   evaluated_card:  "a3f8c2d1..."
//   connected_card:  "b7e2f4a9..."
//   shared_device:   "fp_device_xyz"
//   shared_merchant: "merch_electronics_001"
//   shared_address:  "addr_warehouse_mumbai"
//   topology_matched: "TRIANGULATION_FRAUD_V1"
// → Immediate SCORE_ADJUST +600 applied by GraphAnalysisService
```

---

## Additional Fraud Topology Templates

Per Section A2.4 requirement for at least 3 topology templates:

### Template 2: Synthetic Identity Ring
Cards share the same phone number AND the same IP address subnet,
but have no legitimate reason to be connected (different names, addresses):
```cypher
MATCH (c1:Card)-[:REGISTERED_PHONE]-(phone:PhoneNumber)-[:REGISTERED_PHONE]-(c2:Card)
MATCH (c1)-[:USED_IP]-(ip1:IPAddress)
MATCH (c2)-[:USED_IP]-(ip2:IPAddress)
WHERE ip1.asn = ip2.asn  // same autonomous system = same subnet
AND c1 <> c2
RETURN c1.card_hash, c2.card_hash, phone.phone_hash, ip1.asn
```

### Template 3: Money Mule Network
Account A receives transfers from many cards, then immediately transfers
to Account B — classic money mule "pass-through" pattern:
```cypher
MATCH (cards:Card)-[:TRANSACTED_WITH]->(mule_merchant:Merchant)
MATCH (mule_account:Account)-[:SAME_BENEFICIARY]->(destination:Account)
WITH mule_merchant, count(DISTINCT cards) AS source_card_count, destination
WHERE source_card_count > 5  // 5+ source cards feeding one mule account
RETURN mule_merchant.merchant_id, source_card_count, destination.account_id
```
