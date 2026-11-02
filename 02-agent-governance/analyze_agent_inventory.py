#!/usr/bin/env python3
"""Analyse an agent inventory export and list governance findings.

Input: a CSV export of the agent inventory (for example Microsoft 365 admin center > Agents >
All agents > Export), mapped to the column names below. Real exports change column names over
time: adjust COLUMNS rather than the logic.

Findings:
  - distribution by publisher type and status
  - agents owned by admin accounts
  - agents whose owner is not in the active user list (optional --active-users file)
  - duplicate agent names across makers or platforms
  - inactive agents (no activity for --inactive-days, default 90)
  - agents using uploaded files as knowledge (copies outside SharePoint permissions)
  - agents using public web knowledge or the HTTP connector
  - agents using MCP servers, and preview or Frontier agents

Standard library only. Never commit a real export: run it locally and keep the output local.

Usage:
  python3 analyze_agent_inventory.py inventory.csv [--inactive-days 90] [--today 2026-11-02]
                                                   [--active-users active_upns.txt]
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import Counter, defaultdict
from datetime import date, datetime

COLUMNS = {
    "name": "AgentName",
    "publisher": "PublisherType",
    "platform": "Platform",
    "status": "Status",
    "owner": "Owner",
    "last_activity": "LastActivityDate",
    "knowledge": "KnowledgeSources",
    "tools": "Tools",
    "preview": "Preview",
}

ADMIN_PREFIXES = ("admin", "adm.", "adm_", "adm-", "sa-", "svc")


def parse_date(value: str) -> date | None:
    value = (value or "").strip()
    for fmt in ("%Y-%m-%d", "%d.%m.%Y", "%m/%d/%Y"):
        try:
            return datetime.strptime(value[:10], fmt).date()
        except ValueError:
            continue
    return None


def load(path: str) -> list[dict[str, str]]:
    # utf-8-sig handles the byte order mark that Microsoft admin center exports often include
    with open(path, newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    missing = [c for c in COLUMNS.values() if rows and c not in rows[0]]
    if missing:
        sys.exit(f"Missing columns {missing}. Adjust COLUMNS at the top of the script.")
    return rows


def get(row: dict[str, str], key: str) -> str:
    return (row.get(COLUMNS[key]) or "").strip()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("csv_path")
    parser.add_argument("--inactive-days", type=int, default=90)
    parser.add_argument("--today", default=None, help="Reference date YYYY-MM-DD (default: today)")
    parser.add_argument("--active-users", default=None, help="Text file with one active UPN per line")
    args = parser.parse_args()

    rows = load(args.csv_path)
    today = parse_date(args.today) if args.today else date.today()
    active = None
    if args.active_users:
        with open(args.active_users, encoding="utf-8") as handle:
            active = {line.strip().lower() for line in handle if line.strip()}

    print(f"Agents in inventory: {len(rows)}\n")

    print("By publisher type and status")
    combo = Counter((get(r, "publisher"), get(r, "status")) for r in rows)
    for (publisher, status), count in sorted(combo.items()):
        print(f"  {publisher:<14} {status:<10} {count}")

    custom = [r for r in rows if get(r, "publisher").lower() == "user-created"]
    makers = {get(r, "owner").lower() for r in custom if get(r, "owner")}
    print(f"\nUser-created agents: {len(custom)} by {len(makers)} makers")

    findings: dict[str, list[str]] = defaultdict(list)

    names = defaultdict(list)
    for r in custom:
        names[get(r, "name").lower()].append(r)
    for rows_same_name in names.values():
        if len(rows_same_name) > 1:
            label = ", ".join(f"{get(x, 'owner')} ({get(x, 'platform')})" for x in rows_same_name)
            findings["Duplicate agents"].append(f"{get(rows_same_name[0], 'name')}: {label}")

    for r in custom:
        name, owner = get(r, "name"), get(r, "owner").lower()
        local_part = owner.split("@")[0]
        if local_part.startswith(ADMIN_PREFIXES):
            findings["Owned by an admin or service account"].append(f"{name} ({owner})")
        if active is not None and owner and owner not in active:
            findings["Owner not an active user"].append(f"{name} ({owner})")

        last = parse_date(get(r, "last_activity"))
        if last and (today - last).days > args.inactive_days:
            findings[f"Inactive for more than {args.inactive_days} days"].append(f"{name} (last activity {last})")

        knowledge = get(r, "knowledge").lower()
        tools = get(r, "tools").lower()
        if "uploaded" in knowledge:
            findings["Uploaded files as knowledge (outside SharePoint permissions)"].append(name)
        if "public" in knowledge or "http" in tools.split(", "):
            findings["Public web knowledge or HTTP connector"].append(name)
        if "mcp" in tools:
            findings["Uses MCP servers"].append(f"{name} ({get(r, 'tools')})")

    for r in rows:
        if get(r, "preview").lower() in ("yes", "true"):
            findings["Preview or Frontier agents"].append(f"{get(r, 'name')} ({get(r, 'publisher')})")

    print("\nFindings")
    if not findings:
        print("  none")
    for title, items in findings.items():
        print(f"\n  {title}: {len(items)}")
        for item in items:
            print(f"    - {item}")


if __name__ == "__main__":
    main()
