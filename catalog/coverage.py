#!/usr/bin/env python3
"""Audit actual file coverage against every pinned filename candidate.

This checks review status and file presence, not algorithm correctness or the
completeness of algorithm discovery within each upstream file. Invalid source
candidates can be marked as reviewed exclusions and are counted separately.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "nim": "nim",
             "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}
EXCLUDED_STATUSES = {
    "reviewed_excluded_invalid_source",
    "reviewed_excluded_non_benchmarkable_source",
}
REVIEWED_STATUSES = EXCLUDED_STATUSES | {"reviewed_algorithm_semantics", "reviewed_alias"}


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
    missing_implementations = 0
    complete_algorithms = set()

    def has_implementation(language: str, letter: str, algorithm: str, extension: str,
                           guide: Path) -> bool:
        language_root = ROOT / language / letter
        if any(path.is_file() for path in (
            language_root / f"{algorithm}.{extension}",
            language_root / algorithm / f"{algorithm}.{extension}",
            ROOT / language / f"{algorithm}.{extension}",
            ROOT / language / algorithm / f"{algorithm}.{extension}",
        )):
            return True

        # Some source-backed packages keep ports in the original category
        # directory rather than the benchmark slug's initial-letter directory.
        # In that case, trust only an explicit README link to an existing file
        # inside the matching language tree.
        if not guide.is_file():
            return False
        language_root = (ROOT / language).resolve()
        for target in re.findall(r"\]\(([^)]+)\)", guide.read_text(encoding="utf-8")):
            target = target.split("#", 1)[0]
            if "://" in target:
                continue
            path = (guide.parent / target).resolve()
            if path.suffix != f".{extension}" or not path.is_file():
                continue
            try:
                path.relative_to(language_root)
            except ValueError:
                continue
            return True
        return False

    for candidate in candidates:
        name = candidate["candidate_id"]
        excluded = candidate["review_status"] in EXCLUDED_STATUSES
        target = canonical(candidate)
        if excluded:
            if ("alias_of" in candidate or "benchmark_name" in candidate
                    or candidate.get("additional_benchmark_names")):
                raise ValueError(f"excluded source candidate {name} cannot map to a benchmark")
            benchmark_names = []
        else:
            benchmark_name = target.get("benchmark_name", target["candidate_id"])
            additional_names = target.get("additional_benchmark_names", [])
            candidate_additional_names = candidate.get("additional_benchmark_names", [])
            if not isinstance(additional_names, list) or not isinstance(candidate_additional_names, list):
                raise ValueError(f"additional_benchmark_names must be a list for candidate {name}")
            if candidate is not target:
                additional_names = [*additional_names, *candidate_additional_names]
            benchmark_names = [benchmark_name, *additional_names]
            if (any(not isinstance(item, str) or not item for item in benchmark_names)
                    or len(set(benchmark_names)) != len(benchmark_names)):
                raise ValueError(f"invalid benchmark names for candidate {name}")
        benchmark_details = []
        for index, algorithm in enumerate(benchmark_names):
            contract = target.get("benchmark_contract") if index == 0 else None
            if (isinstance(contract, str) and contract.startswith("benchmarks/")
                    and contract.endswith("/README.md")):
                guide = ROOT / contract
                package_dir = guide.parent
                letter = package_dir.parent.name
            else:
                letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
                package_dir = ROOT / "benchmarks" / letter / algorithm
                guide = package_dir / "README.md"
            workload = guide.with_name("workload.json")
            missing = [language for language, extension in LANGUAGES.items()
                       if not has_implementation(language, letter, algorithm, extension, guide)]
            workload_matches = False
            if workload.is_file():
                spec = json.loads(workload.read_text(encoding="utf-8"))
                workload_matches = spec.get("algorithm") == algorithm
            benchmark_details.append({"algorithm": algorithm, "missing_languages": missing,
                                      "guide_present": guide.is_file(),
                                      "workload_matches": workload_matches})
            if not excluded and ("alias_of" not in candidate or algorithm in candidate_additional_names):
                missing_implementations += len(missing)
        missing = sorted({language for detail in benchmark_details
                          for language in detail["missing_languages"]})
        workload_matches = all(detail["workload_matches"] for detail in benchmark_details)
        reviewed = candidate["review_status"] in REVIEWED_STATUSES
        complete = (not excluded and reviewed and target["review_status"] == "reviewed_algorithm_semantics"
                    and all(not detail["missing_languages"] and detail["guide_present"]
                            and detail["workload_matches"] for detail in benchmark_details))
        if complete:
            complete_algorithms.update(benchmark_names)
        entries.append({"candidate_id": name, "reviewed": reviewed,
                        "source_excluded": excluded,
                        "alias_of": candidate.get("alias_of"),
                        "benchmark_algorithm": benchmark_names[0] if benchmark_names else None,
                        "benchmark_algorithms": benchmark_names,
                        "benchmark_details": benchmark_details,
                        "missing_languages": missing,
                        "guide_present": None if excluded else all(detail["guide_present"] for detail in benchmark_details),
                        "workload_matches": None if excluded else workload_matches,
                        "files_present_and_reviewed": complete})
    summary = {
        "candidate_count": len(entries),
        "reviewed_candidates": sum(entry["reviewed"] for entry in entries),
        "files_present_and_reviewed": sum(entry["files_present_and_reviewed"] for entry in entries),
        "reviewed_excluded_sources": sum(entry["source_excluded"] for entry in entries),
        "reviewed_excluded_invalid_sources": sum(
            candidate["review_status"] == "reviewed_excluded_invalid_source" for candidate in candidates),
        "reviewed_excluded_non_benchmarkable_sources": sum(
            candidate["review_status"] == "reviewed_excluded_non_benchmarkable_source" for candidate in candidates),
            "canonical_candidate_count": sum("alias_of" not in candidate for candidate in candidates),
        "unique_benchmarks_complete": len(complete_algorithms),
        "reviewed_aliases": sum(entry["reviewed"] and entry["alias_of"] is not None for entry in entries),
        "missing_implementation_files": missing_implementations,
        "target_language_count": len(LANGUAGES),
    }
    summary["candidates_remaining"] = (len(entries) - summary["files_present_and_reviewed"]
                                        - summary["reviewed_excluded_sources"])
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
