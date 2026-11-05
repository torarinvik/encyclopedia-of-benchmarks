#!/usr/bin/env python3
"""Score paired ABI samples using means within cases and a geometric mean across cases."""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import statistics


def score(reports: list[dict], baseline: str, candidate: str, cases: list[str]) -> dict:
    if not reports or not cases or len(set(cases)) != len(cases):
        raise ValueError("provide reports and unique workload case IDs")
    if baseline == candidate:
        raise ValueError("baseline and candidate must be distinct variants")
    samples = defaultdict(list)
    seen_rounds = set()
    for report in reports:
        paired, rounds = defaultdict(dict), set()
        for row in report["rows"]:
            if row["variant"] not in (baseline, candidate) or row["case"] not in cases:
                continue
            rounds.add(row["process_round"])
            key, variant = (row["case"], row["batch"]), row["variant"]
            if variant in paired[key]:
                raise ValueError("duplicate batch/variant in a process round")
            value, repetitions = float(row["ns"]), row["repetitions"]
            if not math.isfinite(value) or value <= 0:
                raise ValueError("sample time must be finite and positive")
            if type(repetitions) is not int or repetitions <= 0:
                raise ValueError("repetitions must be a positive integer")
            paired[key][variant] = (value, repetitions)
        if len(rounds) != 1 or rounds & seen_rounds:
            raise ValueError("each report must contain one unique process round")
        seen_rounds.update(rounds)
        by_case = defaultdict(lambda: defaultdict(list))
        for (case, _), variants in paired.items():
            if set(variants) != {baseline, candidate}:
                raise ValueError("unpaired timing batch")
            if variants[baseline][1] != variants[candidate][1]:
                raise ValueError("paired variants used different repetition counts")
            for variant, (value, _) in variants.items():
                by_case[case][variant].append(value)
        if set(by_case) != set(cases):
            raise ValueError("a process round is missing requested workload cases")
        # Each independent process round gets equal weight regardless of batch count.
        for case, variants in by_case.items():
            for variant, values in variants.items():
                samples[case, variant].append(statistics.mean(values))
    per_case = []
    for case in cases:
        before = statistics.mean(samples[case, baseline])
        after = statistics.mean(samples[case, candidate])
        per_case.append({"case": case, "baseline_mean_ns": before,
                         "candidate_mean_ns": after,
                         "time_reduction_percent": 100 * (1 - after / before)})
    before = math.exp(statistics.mean(math.log(c["baseline_mean_ns"]) for c in per_case))
    after = math.exp(statistics.mean(math.log(c["candidate_mean_ns"]) for c in per_case))
    return {"baseline": baseline, "candidate": candidate, "process_rounds": len(reports),
            "cases": per_case, "baseline_geomean_ns": before, "candidate_geomean_ns": after,
            "time_reduction_percent": 100 * (1 - after / before),
            "speedup_percent": 100 * (before / after - 1),
            "regressions": [c["case"] for c in per_case if c["candidate_mean_ns"] > c["baseline_mean_ns"]],
            "method": "arithmetic sample mean per process/case; arithmetic process mean per case; geometric mean across cases",
            "qualification": "descriptive timing score only; correctness, provenance, noise and platform gates need separate evidence"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", type=Path, nargs="+")
    parser.add_argument("--baseline", required=True)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--case", action="append", required=True, dest="cases")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    inputs, receipts = [], []
    for path in args.reports:
        data = path.read_bytes()
        inputs.append(json.loads(data))
        receipts.append({"path": str(path.resolve()), "sha256": hashlib.sha256(data).hexdigest()})
    result = score(inputs, args.baseline, args.candidate, args.cases)
    result["reports"] = receipts
    text = json.dumps(result, indent=2, allow_nan=False) + "\n"
    if args.output:
        args.output.write_text(text)
    print(text, end="")


if __name__ == "__main__":
    main()
