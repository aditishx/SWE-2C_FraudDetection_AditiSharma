# Day 9 Work Log — Graph-Based Fraud Detection Design

**Date:** 7 July 2026
**Commit tag:** `Day09_Graph_Analysis_Design`

## What I did
- Designed complete property graph schema: 9 node types with all properties and
  indexes, 10 relationship types with properties.
- Wrote 5 Cypher query patterns with sample inputs and expected outputs:
  (1) Shortest path to known fraud, (2) Louvain community detection,
  (3) PageRank centrality for infrastructure nodes, (4) temporal connection
  growth for account farming, (5) triangulation fraud topology matching.
- Added 2 additional fraud topology templates (synthetic identity ring,
  money mule network) per Section A2.4 requirement for 3+ templates.
- Evaluated sync vs async graph update strategy — chose async with explicit
  reconciliation mechanism and quantitative justification.
- Designed pruning strategy with per-relationship-type retention windows,
  daily pruning job (batch delete with limit to avoid locking), and
  cold storage archival for RBI 7-year retention compliance.
- Designed read replica strategy separating real-time lookups (primary)
  from analytical algorithms (read replica).
- Produced graph schema entity relationship diagram.

## Key decisions made
1. **Asynchronous graph update chosen over synchronous** — 1-5s staleness
   is acceptable because graph's primary value is pattern detection over
   many transactions, not single-transaction real-time lookup. More
   importantly: synchronous update means Neo4j availability gates transaction
   approval — a single Neo4j slow write could breach the 100ms SLA. That
   coupling is exactly what the Netflix "design for failure" principle (Part C3)
   says to avoid.
2. **MERGE not CREATE for all graph writes** — idempotency is non-negotiable
   for Kafka consumer retry safety. CREATE on retry = duplicate nodes =
   corrupted graph. MERGE on retry = safe update.
3. **Analytical queries (Louvain, PageRank) run on read replica** — these
   algorithms run for minutes on large graphs. Sending them to the primary
   would block all real-time <50ms lookups during the run. Read replica
   has <1s replication lag, which is acceptable for scheduled analytical jobs.
4. **TRANSACTED_WITH retained for 180 days, SHARED_DEVICE for 365 days**
   — different retention because: transaction relationships rotate with spending
   behaviour (6-month pattern is enough); device sharing relationships persist
   because fraudsters reuse device infrastructure for longer.
5. **Pruning uses batched DELETE with LIMIT 50,000** — deleting millions of
   edges in a single transaction locks the graph. Batching keeps the pruning
   job non-blocking during off-peak hours.


