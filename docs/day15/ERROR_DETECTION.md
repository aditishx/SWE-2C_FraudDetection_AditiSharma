# ERROR_DETECTION.md — 5 Embedded Errors Found in Project Document

**Day 15 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 14 July 2026

---

## Error 1 — Typographical Error in Section Heading (Page 10)

**Location:** Part A, Section A2.3 heading
**Error found:** `"A2.3 Anomaly Detection And Machine Laarnign"`
**Why it is an error:** "Laarnign" is a misspelling of "Learning" — likely
a deliberate typographical error embedded as one of the five.
**Correct version:** `"A2.3 Anomaly Detection And Machine Learning"`

---

## Error 2 — Incorrect API Heading (Page 30)

**Location:** Part D, Day 5 section heading
**Error found:** `"Day 5 - API Contract Design (OPENAI and Protobuf)"`
**Why it is an error:** The heading reads "OPENAI" (the AI company) but
the section is about "OpenAPI" (the REST API specification standard, formerly
Swagger). These are entirely different things — OpenAI is an AI research
company; OpenAPI is a specification for describing REST APIs. The deliverable
explicitly requires OpenAPI 3.0 specification files, not anything related
to OpenAI.
**Correct version:** `"Day 5 - API Contract Design (OpenAPI and Protobuf)"`

---

## Error 3 — Conflicting Risk Score Threshold (Pages 12 vs 19)

**Location:** Part A Section A2.5 (page 12) vs Part B Section B1.3 (page 19)
**Error found:** Section A2.5 states the Step-Up Authentication band is
scores **200-599** with SLA **<5s**. However, Section B1.3 (CRO evaluation
criteria) refers to the system needing to handle "new unknown attack types"
— but more critically, the score table in A2.5 has a gap issue: the
Auto-Approve band ends at 199 and Step-Up begins at 200, but no definition
is given for exactly score 199 vs 200 — the boundary condition is ambiguous.
More specifically, in Section B1.2, the financial impact states fraud losses
went from **12 crore INR** to **53 crore INR** in Q3 2025 — but the false
positive rate is stated as spiking from **0.3% to 2.1%**, which is a 7×
increase. The stated consequence ("customer complaints to triple") is
arithmetically inconsistent with a 7× increase in false positives — tripling
implies roughly 3×, not 7×. This is a deliberate embedded inconsistency.
**Correct version:** If false positives increased 7×, customer complaints
would be expected to increase by approximately 5-7×, not "triple" (3×).
The text should read "causing customer complaints to increase significantly"
or give a number consistent with the 7× FP rate increase.

---

## Error 4 — Incorrect rule_ID Field (Sample Rule File)

**Location:** Part A Section A2.2 (page 9) — Rule Configuration Framework,
and cross-referenced against the project's own sample rule schema definition.
The Rule Configuration Framework specifies the metadata field as **`rule_id`**
(lowercase, underscore). However, in the Part D Day 7 deliverable requirements
(page 32), the metadata list includes `rule_id` consistently — but the
brief on page 9 lists the field as `rule_id` in the conditions section and
then references it as `rule_ID` in informal prose. The inconsistency in
capitalisation (`rule_id` vs `rule_ID`) across the document constitutes a
schema definition error — field names in YAML/JSON are case-sensitive.
**Correct version:** The field should be consistently `rule_id` (all lowercase
with underscore) throughout all schema definitions, prose references, and
sample configurations.

**Note:** I preserved `rule_id` (correct) throughout my own Day 7 YAML schema
and sample rules, and flagged `rule_ID` in sample_rules.yaml rule V005 as a
typo that was caught during self-review on Day 15 (see sample_rules.yaml,
rule_ID: rule_V005 — this was an accidental replication of the document's
own embedded error and has been corrected in the final submission).

---

## Error 5 — RBI Fraud Reporting Threshold Inconsistency (Page 13)

**Location:** Part A Section A2.5 — Regulatory Frameworks (page 13)
**Error found:** The document states: *"RBI guidelines for India require
reporting of fraud cases above specified thresholds (2 lakh INR for card
fraud)"*. However, as per the RBI Master Direction on Fraud – Classification
and Reporting by Commercial Banks and Select Financial Institutions (updated
2023), the actual reporting threshold for individual card/internet fraud
cases to be reported to RBI has been revised. Smaller frauds below ₹1 lakh
are reported to the bank's internal fraud monitoring cell; frauds of ₹1 lakh
and above are reported to RBI. The document's stated threshold of "2 lakh INR"
does not match the current RBI Master Direction threshold of ₹1 lakh for
card fraud reporting.
**Correct version:** The fraud reporting threshold should reference
**₹1 lakh INR** (₹1,00,000) for card fraud cases, not ₹2 lakh INR,
as per RBI Master Direction on Fraud (2023 revision).
The architecture's audit-compliance-svc automated STR generation trigger
should be set at ₹1 lakh, not ₹2 lakh, to remain compliant.

---
