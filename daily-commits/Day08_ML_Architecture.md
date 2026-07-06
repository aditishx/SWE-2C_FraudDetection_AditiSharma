# Day 8 Work Log — ML Model Serving and Anomaly Detection Architecture

**Date:** 6 July 2026
**Commit tag:** `Day08_ML_Architecture`

## What I did
- Designed MLflow Model Registry schema with all required metadata per version.
- Specified end-to-end model deployment pipeline (train → validate → stage → canary → production).
- Justified ONNX Runtime over TF Serving and Triton with a comparison table.
- Designed two-tier feature store: batch features (Spark daily, PostgreSQL → Redis)
  and real-time features (Kafka Streams, Redis with TTL), with 11 batch + 11 RT features.
- Documented ensemble strategy: XGBoost (50%) + Isolation Forest (30%) + LSTM (20%)
  with configurable weights per channel.
- Designed model monitoring pipeline: hourly PSI drift detection, daily KS prediction
  drift, daily label reconciliation against chargeback data.
- Specified champion-challenger framework with 7-day shadow period and quantified
  promotion criteria.

## Key decisions made
1. **Canary (not blue-green) for ML model deployment** — 5% live traffic canary
   generates statistically significant fraud detection metrics within hours.
   Blue-green would require 100% traffic switch before seeing production signal.
2. **Feature store has two tiers** — batch features (computed overnight by Spark,
   accurate over 90-day windows) and real-time features (computed per-transaction
   by Kafka Streams, accurate for velocity detection). Using only batch features
   would miss the "3 transactions in the last 5 minutes" signal. Using only
   real-time features would miss the "this amount is 5× the 90-day average" signal.
   Both tiers are necessary.
3. **PSI threshold set at 0.25** — industry standard for "significant drift."
   PSI <0.1 = no drift; 0.1-0.25 = moderate (monitor); >0.25 = significant (retrain).
4. **Chargeback label lag is 30-90 days** — means performance metrics always
   trail current model behaviour by at least a month. This is unavoidable (chargebacks
   require cardholder dispute + bank investigation) — we compensate with PSI/KS
   drift detection that catches degradation earlier without needing labels.
5. **LSTM sequence model weighted at 20%** — lower than XGBoost (50%) because
   sequence models need more history to be reliable and have higher inference
   latency. Weight increased to 30% for UPI channel where transaction sequencing
   patterns are particularly diagnostic.

## Open questions / things to revisit
- Real-time feature store Redis TTL set to 2 hours — needs benchmarking to confirm
  memory usage at 50,000 TPS peak. May need to tune TTL or add Redis cluster sharding.
