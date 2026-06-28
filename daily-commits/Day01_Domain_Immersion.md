# Day 1 Work Log — Domain Immersion and Monolith Analysis

**Date:** 28 June 2026
**Hours logged:** ~8h
**Commit tag:** `Day01_Domain_Immersion`

## What I did
- Studied Part A Sections A1 (microservices fundamentals) and A2 (fraud detection domain knowledge) from the project brief.
- Built a 54-term domain glossary covering payments, fraud types, detection techniques, metrics, architecture terms, and regulatory concepts.
- Analysed the ShieldPay legacy monolith and mapped its functional areas to business capabilities (the language we'll use for service boundaries from Day 2 onward).
- Ran an Event Storming pass on the transaction lifecycle, producing ~11 first-pass domain events with their triggering commands and owning aggregates.

## Key decisions made
1. **Treated "Graph Analysis" as a net-new capability**, not a migrated one — the monolith has no equivalent today, which is itself one reason synthetic-identity fraud rings went undetected in the Q3 2025 crisis.
2. **Split the audit trail into its own aggregate (`AuditEntry`)** rather than treating it as metadata on `Transaction` — this anticipates the Wirecard-style immutability requirement (Part C4) where audit data must never be modifiable by the same process that creates business data.

## Open questions / things to revisit
- Need to confirm exact rule count and category breakdown from "500+ rules" once we design the actual rule schema (Day 7) — for now treating this as background context only.
- The Event Storming diagram today is a *first pass* on the happy path only. Day 6 requires 50+ events including error paths, sagas, and compensating actions — today's 11 events are deliberately a skeleton to validate before expanding.

## Blockers
None.

## Tomorrow's plan (Day 2)
- Apply DDD bounded-context heuristics to the event clusters identified today.
- Decide service granularity (target 8-12 services).
- Produce C4 Level 1 (System Context) diagram and start C4 Level 2 (Container) diagram.
- Build the service decomposition table.
