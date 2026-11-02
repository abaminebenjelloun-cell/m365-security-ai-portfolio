# WS3: Oversharing

**Goal:** know what Copilot will be able to reach before it is turned on, fix the worst exposure, and prove the cleanup over time.

**Platform:** SharePoint admin center, SharePoint Online Management Shell, SharePoint Advanced Management (where licensed).
**Last reviewed:** November 2026.

## Why this is load-bearing

Copilot only shows users what they can already open. Labels (WS1) and DLP (WS2) protect classified content, but an "All Company" site open to everyone, or a forgotten anonymous link, is exposed whatever the label says. In the Secret design (ADR-002), access control relies entirely on SharePoint and OneDrive permissions (lesson L5).

## Approach

| Step | What | Tool |
|---|---|---|
| 1 | Baseline inventory: every site and OneDrive with owner, storage, activity, sharing, label | `Get-SharePointInventory.ps1` |
| 2 | Permission-level oversharing: sites shared with "Everyone except external users", most-shared files | SharePoint Advanced Management, data access governance reports |
| 3 | Prioritise: anonymous links, sites without owner, large inactive sites, sites holding sensitive data | Inventory flags + DLP matches (WS2) |
| 4 | Remediate with site owners: restrict sharing, assign owners, archive or set read-only, apply container labels | SharePoint admin center |
| 5 | Temporary measures where cleanup takes time: Restricted Content Discovery for specific sites, or Restricted SharePoint Search | SharePoint admin center |
| 6 | Re-run the inventory and publish the delta | `Compare-InventorySnapshots.ps1` |

Temporary measures **hide** content from Copilot and search, they do not fix permissions. Present them as such (ADR-006).

## Exposure flags

| Flag | Meaning | Typical action |
|---|---|---|
| `AnonymousLinksAllowed` | Site allows "Anyone" links | Restrict to existing guests or disable |
| `ExternalSharing` | Site allows guest sharing | Confirm business need, review guests |
| `Inactive` | No content change for N days (default 180) | Archive, read-only or delete with owner |
| `NoOwner` | No owner recorded on a classic site | Assign an accountable owner |
| `NoSensitivityLabel` | No container label | Apply label once WS1 groups and sites scope is on |

## Files

| File | Purpose |
|---|---|
| `Get-SharePointInventory.ps1` | Read-only inventory with exposure flags and a summary |
| `Compare-InventorySnapshots.ps1` | Offline delta between two inventories, with an exclusion pattern for changes made by the remediation team itself |
| `sample-data/` | Two synthetic snapshots of the lab tenant to try the delta report |

## Run

```powershell
Connect-SPOService -Url https://contosofiduciaire-admin.sharepoint.com -UseSystemBrowser $true
./01-copilot-readiness/ws3-oversharing/Get-SharePointInventory.ps1 -InactiveDays 180 -IncludeOneDrive

# Delta on the synthetic sample
./01-copilot-readiness/ws3-oversharing/Compare-InventorySnapshots.ps1 `
    -Before ./01-copilot-readiness/ws3-oversharing/sample-data/inventory_before.csv `
    -After  ./01-copilot-readiness/ws3-oversharing/sample-data/inventory_after.csv
```

Expected result on the sample: one site removed (archived), one site added, anonymous-link sites from 2 to 0, sites without owner from 3 to 0, sites without label from 6 to 2.

## Reporting to the sponsor

Keep the client's cleanup metrics clean: changes made by the project team itself (for example admin groups added as site collection administrators on every site) are logged as project changes in the change log and reported separately. `-ExcludeUrlPattern` only removes whole sites (for example test or project sites) from the comparison.
