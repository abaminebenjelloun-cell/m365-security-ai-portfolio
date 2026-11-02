#!/usr/bin/env python3
"""Turn a Copilot Credits consumption export into cost per resource, per use and per owner, in CHF.

Input: daily consumption rows (for example from Power Platform admin center > Licensing >
Copilot Studio, downloaded per environment), mapped to the column names in COLUMNS.

What it answers:
  - Which resources (agents, agent flows) consume the capacity, and what share each takes
  - Cost per active day of each resource, used as a proxy for "one use" when the export is
    aggregated per day (state that assumption in any client report)
  - Share of consumption coming from test resources
  - Consumption per owner and per environment
  - Runway: how many days the allocation lasts at the observed burn rate
  - Reconciliation: the per-resource totals add up to the file total

Unit price: prepaid capacity packs and pay-as-you-go have different prices per credit
(lesson L24). Pass the right one with --usd-per-credit, and the exchange rate used by finance
with --usd-to-chf. Defaults are examples only, verify them before any client figure.

Standard library only.

Usage:
  python3 analyze_credits.py consumption.csv [--usd-per-credit 0.008] [--usd-to-chf 0.80]
                                             [--allocation 25000] [--markdown report.md]
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import defaultdict
from datetime import datetime

COLUMNS = {
    "date": "Date",
    "environment": "Environment",
    "resource": "ResourceName",
    "type": "ResourceType",
    "owner": "Owner",
    "feature": "Feature",
    "credits": "CopilotCredits",
    "is_test": "IsTest",
}


def load(path: str) -> list[dict[str, str]]:
    with open(path, newline="", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        sys.exit("Empty file.")
    missing = [c for c in COLUMNS.values() if c not in rows[0]]
    if missing:
        sys.exit(f"Missing columns {missing}. Adjust COLUMNS at the top of the script.")
    return rows


def chf(credits: float, usd_per_credit: float, usd_to_chf: float) -> float:
    return credits * usd_per_credit * usd_to_chf


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("csv_path")
    parser.add_argument("--usd-per-credit", type=float, default=0.008,
                        help="0.008 = example prepaid pack price, 0.01 = example pay-as-you-go price. Verify.")
    parser.add_argument("--usd-to-chf", type=float, default=0.80, help="Exchange rate used by finance. Example value.")
    parser.add_argument("--allocation", type=float, default=25000, help="Credits available for the period")
    parser.add_argument("--markdown", default=None, help="Optional path to write a Markdown report")
    args = parser.parse_args()

    rows = load(args.csv_path)
    c = COLUMNS

    total = 0.0
    by_resource: dict[str, float] = defaultdict(float)
    days_by_resource: dict[str, set] = defaultdict(set)
    types: dict[str, set] = defaultdict(set)
    envs: dict[str, set] = defaultdict(set)
    by_feature: dict[tuple[str, str], float] = defaultdict(float)
    by_owner: dict[str, float] = defaultdict(float)
    by_env: dict[str, float] = defaultdict(float)
    test_credits = 0.0
    dates = set()

    for r in rows:
        credits = float(r[c["credits"]] or 0)
        resource = r[c["resource"]]
        day = datetime.strptime(r[c["date"]][:10], "%Y-%m-%d").date()
        total += credits
        dates.add(day)
        by_resource[resource] += credits
        days_by_resource[resource].add(day)
        types[resource].add(r[c["type"]])
        envs[resource].add(r[c["environment"]])
        by_feature[(resource, r[c["feature"]])] += credits
        by_owner[r[c["owner"]]] += credits
        by_env[r[c["environment"]]] += credits
        if r[c["is_test"]].strip().lower() in ("yes", "true"):
            test_credits += credits

    # Reconciliation: independent sums must match the file total
    for name, breakdown in (("resource", by_resource), ("owner", by_owner), ("environment", by_env)):
        if abs(sum(breakdown.values()) - total) > 0.01:
            sys.exit(f"Reconciliation failed on {name} breakdown.")

    period_days = (max(dates) - min(dates)).days + 1
    daily_burn = total / period_days
    runway = args.allocation / daily_burn if daily_burn else float("inf")
    price = (args.usd_per_credit, args.usd_to_chf)

    lines: list[str] = []
    out = lines.append
    out("# Copilot Credits cost report (synthetic data)\n")
    out(f"Period: {min(dates)} to {max(dates)} ({period_days} days)  ")
    out(f"Unit price: {args.usd_per_credit} USD per credit, exchange rate {args.usd_to_chf} CHF per USD (assumptions, verify)  ")
    out(f"Total: **{total:,.0f} credits = CHF {chf(total, *price):,.2f}**  ")
    out(f"Share from test resources: {100 * test_credits / total:.1f}%  ")
    out(f"Average burn: {daily_burn:,.0f} credits per day. Allocation of {args.allocation:,.0f} credits lasts "
        f"**{runway:,.0f} days** at this rate\n")

    out("## By resource\n")
    out("| Resource | Type | Environment | Credits | Share | CHF total | Active days | CHF per active day |")
    out("|---|---|---|---:|---:|---:|---:|---:|")
    for resource, credits in sorted(by_resource.items(), key=lambda x: -x[1]):
        rtype, env = " + ".join(sorted(types[resource])), ", ".join(sorted(envs[resource]))
        active_days = len(days_by_resource[resource])
        out(f"| {resource} | {rtype} | {env} | {credits:,.0f} | {100 * credits / total:.1f}% | "
            f"{chf(credits, *price):,.2f} | {active_days} | {chf(credits, *price) / active_days:,.2f} |")

    out("\n## Top resource by feature\n")
    top = max(by_resource, key=by_resource.get)
    out(f"Breakdown of **{top}**:\n")
    out("| Feature | Credits | CHF |")
    out("|---|---:|---:|")
    for (resource, feature), credits in sorted(by_feature.items(), key=lambda x: -x[1]):
        if resource == top:
            out(f"| {feature} | {credits:,.0f} | {chf(credits, *price):,.2f} |")

    out("\n## By owner\n")
    out("| Owner | Credits | Share |")
    out("|---|---:|---:|")
    for owner, credits in sorted(by_owner.items(), key=lambda x: -x[1]):
        out(f"| {owner} | {credits:,.0f} | {100 * credits / total:.1f}% |")

    out("\n## By environment\n")
    out("| Environment | Credits | Share |")
    out("|---|---:|---:|")
    for env, credits in sorted(by_env.items(), key=lambda x: -x[1]):
        out(f"| {env} | {credits:,.0f} | {100 * credits / total:.1f}% |")

    out("\n## Reading notes\n")
    out("- A resource active every day including weekends with a high action count is the signature of "
        "a frequent scheduled agent flow: check its trigger before anything else (lesson L21).")
    out("- \"CHF per active day\" is a proxy for cost per use when the export is aggregated per day. "
        "With execution counts, divide by runs instead.")
    out("- Reconciliation passed: resource, owner and environment breakdowns all add up to the file total.")

    report = "\n".join(lines)
    print(report)
    if args.markdown:
        with open(args.markdown, "w", encoding="utf-8") as handle:
            handle.write(report + "\n")


if __name__ == "__main__":
    main()
