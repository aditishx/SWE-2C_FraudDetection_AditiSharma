# Day 5 Work Log — API Contract Design

**Date:** 2 July 2026
**Commit tag:** `Day05_API_Contracts`

## What I did
- Created OpenAPI 3.0 specification for all 6 external REST APIs with full request/response schemas, error responses, and example payloads.
- Defined Protobuf gRPC service definitions for all 6 internal services (RuleEngine, AnomalyDetection, GraphAnalysis, RiskScoring, CustomerProfile, FeatureStore).
- Each RPC includes deadline/timeout, retry policy, and error code documentation.
- Designed API gateway routing table mapping external REST paths to internal gRPC services.
- Documented all 3 authentication flows (JWT, API Key, OAuth 2.0) and 5-tier rate limiting framework.
- Designed circuit breaker configuration at gateway level.

## Key decisions made
1. **JWT (RS256) as primary auth, API Key only for legacy integrations** — RS256 is asymmetric so the gateway can verify tokens without calling the auth server on every request, keeping latency low.
2. **Rate limit counters stored in Redis with atomic increment** — distributes correctly across multiple gateway instances without race conditions.
3. **Adaptive rate limiting** — if fraud rate spikes above 5%, per-merchant limits automatically tighten by 50%; this directly addresses the enumeration attack pattern from Section A3.2.
4. **`card_number_hash` in request body, never raw PAN** — enforced at schema level (OpenAPI schema doesn't even have a `card_number` field, only `card_number_hash`).

## Tomorrow's plan (Day 6)
- Full Event Storming (50+ events, commands, aggregates, policies, read models).
- All 3 Saga orchestration diagrams with compensating transactions.
- CQRS read model specifications with Kafka Streams topology.
