# PCI DSS Compliance Mapping

**Day 10 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 8 July 2026

> Maps each PCI DSS v4.0 requirement to the specific architectural component
> that satisfies it. Required for the Head of Compliance evaluation (Section B1.3).

| PCI DSS Requirement | Description | Architectural Component | How it's satisfied |
|---|---|---|---|
| **Req 1** | Install and maintain network security controls | Istio NetworkPolicies + Kubernetes NetworkPolicy | Default-deny AuthorizationPolicy; only explicitly permitted service-to-service paths allowed |
| **Req 2** | Apply secure configurations | Distroless/Alpine Docker base images; non-root containers (USER 1000); no default credentials | Docker image build standards (Day 14 samples) |
| **Req 3.3** | Protect stored cardholder data | PAN tokenisation at ingestion; only card_number_hash stored | transaction-ingestion-svc tokenises at entry; no raw PAN in any database |
| **Req 3.5** | Protect primary account numbers | AES-256 encryption at rest for all data stores | HashiCorp Vault-managed keys, 90-day rotation |
| **Req 4.2.1** | Protect cardholder data in transit | mTLS STRICT mode on all internal connections; TLS 1.3 externally | Istio PeerAuthentication (STRICT); API Gateway TLS termination |
| **Req 5** | Protect against malicious software | Distroless base images (no shell, no package manager — minimal attack surface) | Docker build standards; Trivy image scanning in CI/CD (Day 14) |
| **Req 6** | Develop and maintain secure systems | SAST scanning in CI/CD pipeline; dependency vulnerability scanning | CI/CD pipeline (Day 14): SAST + SCA (Snyk/Trivy) gates |
| **Req 7** | Restrict access to cardholder data by business need | RBAC via JWT claims; Istio AuthorizationPolicies; each service only accesses its own datastore | JWT roles (analyst, manager, director); service-per-datastore isolation |
| **Req 8** | Identify users and authenticate access | JWT RS256 with short expiry (15min access token); mTLS mutual authentication between services | API Gateway JWT validation; Istio mTLS service identity |
| **Req 9** | Restrict physical access to cardholder data | Cloud-hosted (AWS/GCP) — physical security delegated to cloud provider | Cloud deployment |
| **Req 10.2** | Implement audit logging | Immutable audit trail in audit-compliance-svc; every decision, rule change, model deployment, data access logged | audit-compliance-svc with Merkle-chained AuditEvents |
| **Req 10.3** | Protect audit logs from destruction | Kafka infinite retention topic with ACL-controlled append-only writes | fraud.audit.events topic with no-delete ACL |
| **Req 10.5** | Retain audit log history for at least 12 months | Kafka infinite retention + cold storage archival | Audit topic retention policy: infinite |
| **Req 11** | Test security of systems regularly | Chaos engineering experiments (Day 14); pentesting schedule | 5 chaos experiments per Section B2; quarterly pentest schedule recommended |
| **Req 12** | Support information security with organisational policies | AI usage policy; data retention policies; role-based access | Documented in this architecture; enforced via RBAC and Vault policies |

## RBI Guidelines Mapping (India-specific)

| RBI Requirement | Architectural Component |
|---|---|
| Real-time fraud monitoring capability | Entire real-time detection pipeline (Days 1-9) |
| Report fraud above ₹2 lakh INR threshold | audit-compliance-svc regulatory query endpoint; automated STR generation |
| Additional Factor of Authentication (AFA) | StepUpAuthRequested action → OTP flow via notification-svc |
| Tokenisation of card-on-file data | transaction-ingestion-svc tokenises at entry point |
| 7-year data retention | PostgreSQL transaction data retention policy; Kafka audit topic infinite retention |
| SAR filing with FIU-IND | audit-compliance-svc STR generation endpoint |

## GDPR Mapping (European cardholders)

| GDPR Requirement | Architectural Component | Conflict with RBI |
|---|---|---|
| Data minimisation | Only card_number_hash and customer_hash stored — never raw PII | None |
| Right to erasure | Pseudonymisation of personal identifiers after retention period | **Conflict:** RBI requires 7-year retention; GDPR allows erasure. Resolution: retain audit records but pseudonymise personal identifiers (replace with hashed values) after GDPR retention period. Jurisdiction config determines which policy applies per cardholder. |
| Purpose limitation | Customer data used only for fraud prevention — documented as legitimate interest | None |
| Data subject access | audit-compliance-svc query endpoint returns all decisions for a given card | None |
