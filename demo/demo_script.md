# Shariah Compliance Monitoring

**Malaysia - Islamic Finance**
Use case: Shariah Compliance

> Automated Shariah compliance validation for Malaysia's RM 2.3T Islamic finance sector — AI_PARSE_DOCUMENT extracts contract terms, Cortex Search indexes fatwas, and Cortex Complete validates against BNM guidelines.

## Why Snowflake

Snowflake automates Shariah compliance monitoring — AI parses contracts, indexes 200 fatwas, validates against BNM guidelines, and alerts compliance officers to non-conformance in real time

- **AI_PARSE_DOCUMENT on Islamic financing contracts** - Only demo extracting Shariah-specific terms (murabahah, ijarah, musharakah) from legal documents
- **Cortex Search on fatwa library** - Only demo indexing 200 Islamic jurisprudence rulings for semantic search
- **ML.CLASSIFICATION for compliance risk scoring** - Scores Shariah non-compliance risk using contract terms and BNM guideline parameters
- **Fatwa conflict detection** - Automatically surfaces conflicting DSN rulings across different time periods
- **BNM guideline auto-validation** - Maps extracted contract terms directly to BNM regulatory requirements
- **Malaysian Islamic finance context** - RM 2.3T sector with authentic Shariah governance terminology and BNM framework

## What is deployed

| | |
|---|---|
| Database | `MY_ISLAMIC_FINANCE_SHARIAH` |
| Service | `MY_ISLAMIC_FINANCE_SHARIAH_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.BNM_GUIDELINES` (20 rows) |
| Fact table | `RAW.COMPLIANCE_EVENTS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Murabahah, Ijarah, Musharakah, Tawarruq

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_ISLAMIC_FINANCE_SHARIAH
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Shariah AUM | `RM 847B` | total across Bnm Guidelines |
| SAC Resolutions | `24` | average per event |
| Products Screened | `1,247` | total across Bnm Guidelines |
| Compliance Rate | `100%` | average per event |
| Equities Screened | `847` | total across Bnm Guidelines |
| Sukuk Reviewed | `124` | total across Bnm Guidelines |
| New Rulings | `4` | average per event |


## Demo flow

1. Compliance Overview
2. Contract Validation
3. Fatwa Intelligence
4. Ask AI
5. Architecture & Data

## Talking points

- **RM 2.3T** - total Islamic assets under Shariah governance
- **12 contracts** - flagged non-compliant this quarter
- **6 DSN rulings** - in conflict on commodity murabahah
- **200 fatwas** - indexed and searchable via Cortex Search
- **98.4%** - overall Shariah compliance rate
- **5,000 contracts** - actively monitored for compliance

## Business impact

- Malaysia's Islamic banking assets reached RM 1.2 trillion, representing 40.3% of total banking system (Bank Negara Malaysia)
- Islamic finance sector contributed 25.6% to Malaysia's overall financial system in 2023 (MIFC)
- Manual Shariah compliance review takes 4-6 weeks per product — AI reduces to hours (Deloitte Islamic Finance)
- Non-compliance penalties from BNM can reach RM 25 million per incident (IFSA 2013)

---
Generated from `generator/demo_specs/aws-malaysia-islamic-finance-shariah.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-islamic-finance-shariah` instead.
