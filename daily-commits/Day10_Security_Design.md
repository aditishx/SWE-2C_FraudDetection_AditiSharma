# Day 10 Work Log — Service Mesh and Security Design

**Date:** 8 July 2026
**Commit tag:** `Day10_Security_Design`

## What I did
- Wrote complete Istio configuration across 4 resource types:
  PeerAuthentication (STRICT mTLS namespace-wide, zero exceptions),
  AuthorizationPolicies (default-deny + explicit per-service allows),
  DestinationRules (connection pools, TLS settings, outlier detection per service),
  VirtualServices (blue-green for Rule Engine, canary for Anomaly Detection).
- Built service communication matrix (11×11) defining every allowed
  connection with mechanism (gRPC, REST, Kafka).
- Wrote data encryption strategy: AES-256 at rest for all stores,
  mTLS in transit everywhere, PAN tokenisation at ingestion, key rotation schedule.
- Mapped all PCI DSS v4.0 requirements, RBI guidelines, and GDPR requirements
  to specific architectural components — with explicit handling of the
  RBI (7-year retention) vs GDPR (right to erasure) conflict.

## Key decisions made
1. **STRICT mTLS with zero exceptions** — the brief (Section A3.1) explicitly
   states "no exceptions." Even internal health-check traffic uses mTLS.
   This prevents an attacker who compromises one pod from impersonating
   another service (lateral movement).
2. **Default-deny AuthorizationPolicy with explicit per-service allows** —
   safer than default-allow with selective denies. Any new service added to
   the namespace is automatically denied all traffic until explicitly allowed.
   Forces conscious decision-making about every communication path.
3. **notification-svc explicitly cannot call rule-engine-svc** — enforced at
   Istio policy level, not just by convention. Section A3.1 calls this out
   specifically as the canonical example of least-privilege enforcement.
4. **RBI vs GDPR conflict resolved by jurisdiction-based config** — a
   Kubernetes ConfigMap per deployment region controls which retention/erasure
   policy applies. Indian cardholders: 7-year retention (RBI). EU cardholders:
   pseudonymisation after GDPR retention period. Neither policy is globally
   applied — they coexist via configuration.
5. **Different DestinationRule connection pool sizes per service** — critical-path
   services (rule-engine, risk-scoring) have stricter connectTimeout (5ms) and
   faster outlier ejection (3 consecutive errors). notification-svc has looser
   settings (50ms timeout, 10 errors before ejection) because it's not
   latency-critical and retries handle transient failures naturally.

## Open questions / things to revisit
- card-management (referenced in Day 6 Sagas) decided: it will be handled by
  the Core Banking System integration via the Anti-Corruption Layer during the
  migration period, not a new microservice. Card freeze/block operations will
  be API calls to CBS with the ACL translating between our domain model and
  the CBS's legacy API.
