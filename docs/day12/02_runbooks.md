# Runbooks — P1 and P2 Alerts

**Day 12 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 10 July 2026

> Each P1 and P2 alert must have an associated runbook per Section A3.3.
> Runbooks specify: symptoms, diagnosis steps, remediation steps, escalation.

---

## P1-001: Transaction Pipeline Down

**Alert:** `TransactionPipelineDown` — transaction rate = 0 for 2+ minutes
**Impact:** All transactions rejected. Complete revenue and fraud-detection loss.
**On-call response time:** Immediate (PagerDuty auto-escalates after 5 minutes)

### Symptoms
- Stat panel "Transactions/second" shows 0 on Dashboard 1
- Card networks receiving 503 or timeout responses
- `fraud:transaction_rate:1m` metric = 0

### Diagnosis steps
```bash
# 1. Check pod health
kubectl get pods -n fraud-detection | grep transaction-ingestion

# 2. Check recent pod events
kubectl describe pod <txn-ingestion-pod> -n fraud-detection | tail -30

# 3. Check logs for errors
kubectl logs -n fraud-detection -l app=transaction-ingestion-svc --tail=100

# 4. Check if Kafka is reachable
kubectl exec -n fraud-detection <txn-ingestion-pod> -- \
  kafka-broker-api-versions --bootstrap-server kafka:9092

# 5. Check API Gateway is routing correctly
kubectl logs -n kong -l app=kong --tail=50 | grep "transaction"
```

### Remediation steps
| Root cause | Action |
|---|---|
| All pods CrashLooping | `kubectl rollout undo deployment/transaction-ingestion-svc -n fraud-detection` |
| OOMKilled (memory limit hit) | Scale up: `kubectl scale deployment/transaction-ingestion-svc --replicas=10` |
| Kafka unreachable | Check Kafka broker pods; restart consumer if broker recovered |
| Database connection exhausted | Check PostgreSQL connection pool; restart service to reset connections |
| Config/secret missing | Check Vault is reachable; re-sync external secrets |

### Escalation
- 0-5 min: On-call SRE investigates
- 5 min: Auto-escalate to Platform Lead + CTO notification
- 15 min: Incident commander declared; war-room started in #incident-channel

---

## P1-002: Fraud Detection Rate Collapsed

**Alert:** `FraudDetectionRateCollapsed` — decline + review rate < 0.2% for 10 minutes
**Impact:** Fraud passing through undetected. Potential financial loss.
**On-call response time:** Immediate

### Symptoms
- Fraud decision pie chart shows near-100% AUTO_APPROVE
- Rule trigger frequency drops to near-zero
- ML scores clustering near 0 (all transactions scoring "safe")

### Diagnosis steps
```bash
# 1. Check Rule Engine pod health
kubectl get pods -n fraud-detection | grep rule-engine

# 2. Check if rules are loaded (rule count > 0)
kubectl exec -n fraud-detection <rule-engine-pod> -- \
  curl -s localhost:8080/actuator/health | jq '.components.ruleCache'

# 3. Check Kafka consumer lag — is rule engine consuming?
kafka-consumer-groups --bootstrap-server kafka:9092 \
  --describe --group rule-engine-cg

# 4. Check ML model serving health
kubectl logs -n fraud-detection -l app=anomaly-detection-svc --tail=50

# 5. Check feature store (Redis) connectivity
kubectl exec -n fraud-detection <anomaly-detection-pod> -- \
  redis-cli -h redis ping
```

### Remediation steps
| Root cause | Action |
|---|---|
| Rule cache empty after restart | Trigger rule reload: POST /actuator/reload-rules |
| Rule Engine consuming wrong Kafka offset | Reset consumer group offset to latest |
| ML model failed to load (warm-up error) | Restart anomaly-detection-svc; check MLflow connectivity |
| Feature store (Redis) down | Fall back to population-average features (automatic); restore Redis |
| All detection engines on fallback | Alert CRO immediately; manually review high-value transactions |

### Escalation
- 0-5 min: On-call SRE investigates
- 5 min: CRO and Fraud Manager notified
- 10 min: Manual review queue activated for all transactions above ₹10,000

---

## P2-001: Service Error Rate High

**Alert:** `ServiceErrorRateHigh` — any service error rate >1% for 5 minutes
**Impact:** Depends on service — critical path services directly affect transaction processing

### Diagnosis steps
```bash
# Identify which service and what errors
kubectl logs -n fraud-detection -l app=<service-name> --tail=200 | grep "ERROR\|FATAL"

# Check for recent deployments that might have caused the regression
kubectl rollout history deployment/<service-name> -n fraud-detection

# Check downstream dependencies
kubectl exec -n fraud-detection <pod> -- curl -s <dependency>/healthz
```

### Remediation steps
| Scenario | Action |
|---|---|
| Error spike started after deployment | Rollback: `kubectl rollout undo deployment/<service-name>` |
| Downstream dependency (DB, Redis) failing | Check dependency health; service will auto-recover when dependency recovers |
| Memory pressure causing errors | Scale out: `kubectl scale deployment/<service-name> --replicas=+2` |

---

## P2-002: Kafka Consumer Lag High

**Alert:** `KafkaConsumerLagHigh` — lag >10,000 messages on critical path topic for 5 minutes
**Impact:** Detection pipeline falling behind — fraud decisions delayed

### Diagnosis steps
```bash
# Check which consumer group is lagging
kafka-consumer-groups --bootstrap-server kafka:9092 \
  --describe --group <consumer-group-id>

# Check consumer pod resource usage
kubectl top pods -n fraud-detection -l app=<consuming-service>

# Check if messages are poison (causing processing errors)
kubectl logs -n fraud-detection -l app=<consuming-service> | grep "deserializ\|schema"
```

### Remediation steps
| Root cause | Action |
|---|---|
| Consumer pods resource-constrained | Scale out consumer deployment |
| Poison message in partition | Check DLQ topic; skip offset if confirmed poison |
| Traffic spike above normal | Verify Kafka partitions and consumer instances are balanced |
| Schema version mismatch | Check Schema Registry; may need schema evolution |
