# Graph Schema — Entity Relationship Diagram

**Day 9 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 7 July 2026

```mermaid
graph TD
    CARD["🃏 Card\ncard_hash · bin · issuer\nproduct_type · risk_tier · is_blocked"]
    ACCOUNT["🏦 Account\naccount_id · type · status\nopened_at · bank_code"]
    CUSTOMER["👤 Customer\ncustomer_hash · risk_tier\nkyc_type · created_at"]
    DEVICE["📱 Device\ndevice_fingerprint · os\nbrowser · is_jailbroken"]
    IP["🌐 IPAddress\nip_hash · country · city\nis_vpn · is_proxy · is_tor"]
    PHONE["📞 PhoneNumber\nphone_hash · carrier\ncountry · is_voip"]
    EMAIL["📧 Email\nemail_hash · domain\nis_disposable"]
    ADDRESS["🏠 PhysicalAddress\naddress_hash · city\nstate · country · pincode"]
    MERCHANT["🏪 Merchant\nmerchant_id · name · mcc\nrisk_category · is_on_watchlist"]

    CUSTOMER -->|OWNS| CARD
    CUSTOMER -->|OWNS| ACCOUNT
    CARD -->|LINKED_ACCOUNT| ACCOUNT
    CARD -->|"TRANSACTED_WITH\ntimestamp · amount · channel"| MERCHANT
    CARD -->|"SHARED_DEVICE\nfirst_shared_at · share_count"| DEVICE
    CARD -->|"SHARED_ADDRESS\nrelationship_type"| ADDRESS
    CARD -->|"REGISTERED_PHONE\nregistration_date"| PHONE
    CARD -->|"REGISTERED_EMAIL\nregistration_date"| EMAIL
    CARD -->|"USED_IP\ntimestamp · session_duration"| IP
    ACCOUNT -->|"SAME_BENEFICIARY\ntransfer_count · total_amount"| ACCOUNT

    style CARD fill:#B5D4F4,stroke:#185FA5,color:#042C53
    style ACCOUNT fill:#B5D4F4,stroke:#185FA5,color:#042C53
    style CUSTOMER fill:#B5D4F4,stroke:#185FA5,color:#042C53
    style DEVICE fill:#FAC775,stroke:#854F0B,color:#412402
    style IP fill:#FAC775,stroke:#854F0B,color:#412402
    style PHONE fill:#FAC775,stroke:#854F0B,color:#412402
    style EMAIL fill:#FAC775,stroke:#854F0B,color:#412402
    style ADDRESS fill:#FAC775,stroke:#854F0B,color:#412402
    style MERCHANT fill:#C0DD97,stroke:#3B6D11,color:#173404
```

**Blue nodes** = identity entities (Card, Account, Customer)
**Amber nodes** = infrastructure entities — the key fraud signals
(fraudsters share infrastructure: same device, IP, phone, email, address)
**Green nodes** = merchants (reference data, rarely the primary fraud actor)

The fraud detection intuition: legitimate cardholders have mostly unique
infrastructure (one phone, one home address, their own device). Synthetic
identity rings share infrastructure — many cards pointing to the same device
or IP address is the graph signature we're hunting for.
