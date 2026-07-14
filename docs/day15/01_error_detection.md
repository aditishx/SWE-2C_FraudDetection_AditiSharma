# ERROR_DETECTION — 5 Embedded Errors Found in Project Brief

**Day 15 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Date:** 14 July 2026

---

## Error 1 — Typographical Error in Section A2.3 Heading

**Location:** Part A, Section A2.3 heading
**Original text:** "A2.3 Anomaly Detection And Machine Laarnign"
**Error:** "Laarnign" is a misspelling of "Learning"
**Corrected text:** "A2.3 Anomaly Detection And Machine Learning"
**Significance:** While typographical, this appears in a section heading which
is the primary navigation element for the document. In a production architecture
document submitted to regulators (PCI DSS auditors, RBI inspectors), a heading
error signals lack of review rigour. In our architecture, we enforce documentation
review gates in the CI/CD pipeline (Day 14) — the equivalent of a spell-check
gate in a docs-as-code workflow.

---

## Error 2 — Section D, Day 5 References "OPENAI" Instead of "OpenAPI"

**Location:** Part D, Section D2, Day 5 heading
**Original text:** "Day 5 - API Contract Design (OPENAI and Protobuf)"
**Error:** "OPENAI" should be "OpenAPI" — OpenAI is an AI company; OpenAPI
is the REST API specification standard (formerly Swagger) used for documenting
REST endpoints.
**Corrected text:** "Day 5 - API Contract Design (OpenAPI and Protobuf)"
**Significance:** This is a meaningful semantic error, not just a typo. OpenAPI
3.0 is the specification we implement in `api-specs/openapi.yaml`. Confusing
OpenAI (an AI company) with OpenAPI (a REST documentation standard) in a
fintech architecture brief indicates either a copy-paste error or a genuine
conceptual confusion — both of which an architect reviewing the document should
catch and flag.

---

## Error 3 — Incorrect RBI Fraud Reporting Threshold in Section A2.5

**Location:** Part A, Section A2.5 (Risk Scoring and Explainability),
Regulatory Frameworks paragraph
**Original text:** "RBI guidelines for India require reporting of fraud cases
above specified thresholds (2 lakh INR for card fraud)"
**Error:** The RBI fraud reporting threshold cited (₹2 lakh / ₹200,000 INR)
is inconsistent with current RBI Master Directions on Fraud, which require
banks to report all individual fraud cases above ₹1 lakh (₹100,000 INR) to
the RBI, and cases above ₹1 crore (₹10,000,000 INR) must be reported within
specific timelines to the Board.
**Impact on architecture:** Our audit-compliance-svc STR generation logic
(Section A2.5) and the regulatory query endpoints must be calibrated to the
correct threshold — ₹1 lakh, not ₹2 lakh. An architect accepting the brief's
value without verification would build a non-compliant system that misses
a significant number of required reports.
**Source:** RBI Master Direction — Frauds Classification and Reporting by
commercial banks and select FIs (updated 2023).

---

## Error 4 — Contradiction Between Section A1.4 and Section A2.5 on Latency SLA

**Location:** Part A, Sections A1.4 and A2.5
**Section A1.4 states:** "gRPC calls between the Rule Engine, Anomaly Detection,
and Risk Scoring services must complete within a combined latency budget of
100 milliseconds at the 99th percentile."
**Section A2.5 states (risk score table):** "Auto-Approve SLA: < 100ms" and
"Auto-Decline SLA: < 100ms" — implying the entire pipeline including network
ingress and API gateway must complete in 100ms.
**Error / contradiction:** Section A1.4 assigns the entire 100ms budget to only
the internal gRPC hops (Rule Engine → Anomaly Detection → Risk Scoring), while
Section A2.5 implies 100ms covers the full end-to-end pipeline including API
Gateway, Transaction Ingestion enrichment (which alone costs ~20ms for external
enrichment API calls), and the response back to the card network.
**Resolution applied in our architecture:** We interpreted the 100ms as the
end-to-end pipeline SLA and designed the internal gRPC hops to consume only
~53ms of that budget (per the Day 3 and Day 13 latency breakdown), leaving
headroom for ingress (~5ms), enrichment (~20ms), and Kafka publish/consume (~7ms).
This is the only interpretation that produces a workable system — 100ms for
internal gRPC hops alone would make the enrichment step (which requires external
API calls) impossible to fit within the budget.

---

## Error 5 — Section B1.4 Challenge Level Points Sum Does Not Equal 1000

**Location:** Part B, Section B1.4, Progressive Challenge Levels table
**Original table:**

| Level | Points |
|---|---|
| 1 — Decomposition | 150 |
| 2 — Communication | 200 |
| 3 — Detection Engineering | 200 |
| 4 — Resilience & Security | 150 |
| 5 — Observability & Ops | 150 |
| 6 — Deployment & Present | 150 |
| **Total** | **1,000** |


**Actual error:** Part F (Submission Protocol) states: "Projects are assessed
using a comprehensive 1000-point rubric covering **seven** dimensions: Problem
Understanding, Solution Quality, Research & Analysis, Presentation & Clarity,
Innovation & Creativity, Feasibility & Practicality and CV alignment."
Part B1.4 defines **six** challenge levels summing to 1,000 points.
The two scoring frameworks are inconsistent — Part B uses a level-based
(6-level) scoring model; Part F uses a dimension-based (7-dimension) rubric.
The correct interpretation is that Part F's 7-dimension rubric is
the actual assessment framework, and Part B's level-based points are a
gamification overlay — but the brief never states this explicitly.
