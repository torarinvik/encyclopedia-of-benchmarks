#!/usr/bin/env python3
"""Audit actual file coverage against every pinned filename candidate.

This checks review status and file presence, not algorithm correctness or the
completeness of algorithm discovery within each upstream file.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "nim": "nim",
             "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def audit() -> dict:
    catalog = json.loads((ROOT / "catalog/algorithm-candidates.json").read_text(encoding="utf-8"))
    candidates = catalog["candidates"]
    if len(candidates) != catalog["candidate_count"]:
        raise ValueError("candidate_count does not match the actual candidate list")
    names = [candidate["candidate_id"] for candidate in candidates]
    if len(set(names)) != len(names):
        raise ValueError("candidate IDs are not unique")
    by_name = {candidate["candidate_id"]: candidate for candidate in candidates}

    def canonical(candidate: dict) -> dict:
        seen = set()
        current = candidate
        while "alias_of" in current:
            name = current["candidate_id"]
            if name in seen:
                raise ValueError(f"candidate alias cycle includes {name}")
            seen.add(name)
            target_name = current["alias_of"]
            if target_name not in by_name:
                raise ValueError(f"candidate alias target does not exist: {name} -> {target_name}")
            current = by_name[target_name]
        return current

    entries = []
    complete_by_name = {}
    for candidate in candidates:
        name = candidate["candidate_id"]
        target = canonical(candidate)
        benchmark_name = target["candidate_id"]
        letter = benchmark_name[0] if benchmark_name[0].isalpha() else "0-9"
        guide = ROOT / "benchmarks" / letter / benchmark_name / "README.md"
        workload = guide.with_name("workload.json")
        missing = [language for language, extension in LANGUAGES.items()
                   if not (ROOT / language / letter / f"{benchmark_name}.{extension}").is_file()]
        workload_matches = False
        if workload.is_file():
            spec = json.loads(workload.read_text(encoding="utf-8"))
            workload_matches = spec.get("algorithm") == benchmark_name
        reviewed = candidate["review_status"] == "reviewed_algorithm_semantics"
        complete = (reviewed and target["review_status"] == "reviewed_algorithm_semantics"
                    and not missing and guide.is_file() and workload_matches)
        if name == benchmark_name:
            complete_by_name[name] = complete
        entries.append({"candidate_id": name, "reviewed": reviewed,
                        "alias_of": candidate.get("alias_of"),
                        "benchmark_algorithm": benchmark_name,
                        "missing_languages": missing, "guide_present": guide.is_file(),
                        "workload_matches": workload_matches,
                        "files_present_and_reviewed": complete})
    unique_complete = sum(complete_by_name.values())
    summary = {
        "candidate_count": len(entries),
        "reviewed_candidates": sum(entry["reviewed"] for entry in entries),
        "files_present_and_reviewed": sum(entry["files_present_and_reviewed"] for entry in entries),
        "canonical_candidate_count": sum("alias_of" not in candidate for candidate in candidates),
        "unique_benchmarks_complete": unique_complete,
        "reviewed_aliases": sum(entry["reviewed"] and entry["alias_of"] is not None for entry in entries),
        "missing_implementation_files": sum(
            len(entry["missing_languages"]) for entry in entries if entry["alias_of"] is None),
        "target_language_count": len(LANGUAGES),
    }
    summary["candidates_remaining"] = len(entries) - summary["files_present_and_reviewed"]
    return {"scope": "Pinned filename candidate review and file presence; runtime correctness is separate",
            "summary": summary, "candidates": entries}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="Optional full JSON report path")
    parser.add_argument("--require-complete", action="store_true",
                        help="Fail when any candidate still needs review, a port, a guide, or a workload")
    args = parser.parse_args()
    report = audit()
    print(json.dumps(report["summary"], indent=2))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return int(args.require_complete and report["summary"]["candidates_remaining"] != 0)


if __name__ == "__main__":
    raise SystemExit(main())
