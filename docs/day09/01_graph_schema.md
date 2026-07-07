# Graph Database Schema — Property Graph Design

**Day 9 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 7 July 2026

> Technology choice: **Neo4j** (self-hosted on Kubernetes).
> Justification: native graph storage with index-free adjacency for O(1)
> relationship traversal, mature Cypher query language, built-in Graph Data
> Science library (community detection, centrality, path finding), and ACID
> transaction support. Amazon Neptune is the alternative if deploying to AWS
> managed infrastructure — operationally simpler but Cypher-compatible only
> via openCypher subset. JanusGraph is open-source but adds operational
> complexity (Cassandra/HBase backend) without meaningful query-language benefit
> for our use case. Neo4j chosen for development velocity and GDS library depth.

---

## Node Types

### Card
```
(:Card {
  card_hash:        String   // SHA-256 of PAN — never raw PAN stored in graph
  bin:              String   // first 8 digits — identifies issuing bank
  issuer:           String   // issuing bank name
  product_type:     String   // CREDIT | DEBIT | PREPAID
  network:          String   // VISA | MASTERCARD | RUPAY
  created_at:       DateTime
  risk_tier:        Float    // 0-1, updated by CustomerProfileService
  is_blocked:       Boolean
})
INDEX ON :Card(card_hash)    // primary lookup key
```

### Account
```
(:Account {
  account_id:       String
  type:             String   // SAVINGS | CURRENT | WALLET
  status:           String   // ACTIVE | FROZEN | CLOSED
  opened_at:        DateTime
  bank_code:        String   // IFSC prefix
})
INDEX ON :Account(account_id)
```

### Customer
```
(:Customer {
  customer_hash:    String   // SHA-256 of customer ID — never raw ID
  risk_tier:        Float    // 0-1
  kyc_type:         String   // FULL | MINIMAL | VIDEO
  created_at:       DateTime
})
INDEX ON :Customer(customer_hash)
```

### Device
```
(:Device {
  device_fingerprint: String  // composite hash of device attributes
  os:               String
  browser:          String
  first_seen:       DateTime
  last_seen:        DateTime
  is_jailbroken:    Boolean
  imei_hash:        String
})
INDEX ON :Device(device_fingerprint)
```

### IPAddress
```
(:IPAddress {
  ip_hash:          String   // SHA-256 of IP address
  country:          String
  city:             String
  is_vpn:           Boolean
  is_proxy:         Boolean
  is_tor:           Boolean
  asn:              String   // Autonomous System Number
  first_seen:       DateTime
})
INDEX ON :IPAddress(ip_hash)
```

### PhoneNumber
```
(:PhoneNumber {
  phone_hash:       String   // SHA-256 of phone number
  carrier:          String
  country:          String
  is_voip:          Boolean
  registered_at:    DateTime
})
INDEX ON :PhoneNumber(phone_hash)
```

### Email
```
(:Email {
  email_hash:       String   // SHA-256 of email address
  domain:           String
  is_disposable:    Boolean  // flagged by disposable email detection service
  first_seen:       DateTime
})
INDEX ON :Email(email_hash)
```

### PhysicalAddress
```
(:PhysicalAddress {
  address_hash:     String   // SHA-256 of normalised address string
  city:             String
  state:            String
  country:          String
  pincode:          String
  is_high_risk:     Boolean  // e.g. freight-forwarding warehouses
})
INDEX ON :PhysicalAddress(address_hash)
```

### Merchant
```
(:Merchant {
  merchant_id:      String
  name:             String
  mcc:              String
  risk_category:    String   // LOW | MEDIUM | HIGH | CRITICAL
  country:          String
  is_on_watchlist:  Boolean
})
INDEX ON :Merchant(merchant_id)
FULLTEXT INDEX ON :Merchant(name)  // for fuzzy merchant name matching
```

---

## Edge Types (Relationships)

```
(:Card)-[:TRANSACTED_WITH {
  transaction_id:  String
  timestamp:       DateTime
  amount:          Float
  currency:        String
  channel:         String
  risk_decision:   String   // AUTO_APPROVE | STEP_UP | REVIEW | DECLINE
}]->(:Merchant)

(:Card)-[:SHARED_DEVICE {
  first_shared_at: DateTime
  last_shared_at:  DateTime
  share_count:     Integer
}]-(:Device)

(:Card)-[:SHARED_ADDRESS {
  relationship_type: String  // BILLING | SHIPPING | BOTH
  first_seen_at:   DateTime
}]-(:PhysicalAddress)

(:Card)-[:REGISTERED_PHONE {
  registration_date: DateTime
}]-(:PhoneNumber)

(:Card)-[:REGISTERED_EMAIL {
  registration_date: DateTime
}]-(:Email)

(:Card)-[:USED_IP {
  timestamp:       DateTime
  session_duration_seconds: Integer
}]-(:IPAddress)

(:Account)-[:SAME_BENEFICIARY {
  transfer_count:  Integer
  first_transfer:  DateTime
  total_amount:    Float
}]-(:Account)

(:Customer)-[:OWNS]->(:Card)
(:Customer)-[:OWNS]->(:Account)

(:Card)-[:LINKED_ACCOUNT {
  link_type:       String   // PRIMARY | SECONDARY | SUPPLEMENTARY
}]-(:Account)
```

---

## Graph Indexes Summary

| Index | Type | Purpose |
|---|---|---|
| `Card(card_hash)` | B-tree unique | Primary card lookup |
| `Device(device_fingerprint)` | B-tree unique | Device deduplication |
| `IPAddress(ip_hash)` | B-tree unique | IP lookup |
| `Merchant(merchant_id)` | B-tree unique | Merchant lookup |
| `Merchant(name)` | Full-text | Fuzzy merchant name search |
| `PhoneNumber(phone_hash)` | B-tree unique | Phone deduplication |
| `Email(email_hash)` | B-tree unique | Email deduplication |
| `PhysicalAddress(address_hash)` | B-tree unique | Address deduplication |
| `TRANSACTED_WITH(timestamp)` | B-tree | Time-windowed transaction queries |
