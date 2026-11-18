# Copilot Credits cost report (synthetic data)

Period: 2026-10-01 to 2026-10-31 (31 days)  
Unit price: 0.008 USD per credit, exchange rate 0.8 CHF per USD (assumptions, verify)  
Total: **17,491 credits = CHF 111.95**  
Share from test resources: 3.9%  
Average burn: 564 credits per day. Allocation of 25,000 credits lasts **44 days** at this rate

## By resource

| Resource | Type | Environment | Credits | Share | CHF total | Active days | CHF per active day |
|---|---|---|---:|---:|---:|---:|---:|
| Mailbox Poller | Agent flow | Default | 9,373 | 53.6% | 59.99 | 31 | 1.94 |
| Invoice Triage | Agent + Agent flow | Maker-Finance | 4,701 | 26.9% | 30.09 | 24 | 1.25 |
| HR FAQ (legacy) | Agent | Default | 1,860 | 10.6% | 11.90 | 23 | 0.52 |
| Client Onboarding Helper | Agent | Default | 875 | 5.0% | 5.60 | 20 | 0.28 |
| Test agent 2 | Agent | Default | 682 | 3.9% | 4.36 | 8 | 0.55 |

## Top resource by feature

Breakdown of **Mailbox Poller**:

| Feature | Credits | CHF |
|---|---:|---:|
| Agent flow actions | 9,373 | 59.99 |

## By owner

| Owner | Credits | Share |
|---|---:|---:|
| chloe@contosofiduciaire.onmicrosoft.com | 10,248 | 58.6% |
| alice@contosofiduciaire.onmicrosoft.com | 4,701 | 26.9% |
| bruno@contosofiduciaire.onmicrosoft.com | 1,860 | 10.6% |
| admin@contosofiduciaire.onmicrosoft.com | 682 | 3.9% |

## By environment

| Environment | Credits | Share |
|---|---:|---:|
| Default | 12,790 | 73.1% |
| Maker-Finance | 4,701 | 26.9% |

## Reading notes

- A resource active every day including weekends with a high action count is the signature of a frequent scheduled agent flow: check its trigger before anything else (lesson L21).
- "CHF per active day" is a proxy for cost per use when the export is aggregated per day. With execution counts, divide by runs instead.
- Reconciliation passed: resource, owner and environment breakdowns all add up to the file total.
