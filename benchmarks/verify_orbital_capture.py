#!/usr/bin/env python3
"""Verify the orbital-capture radius and area ports in all target languages."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHMS = {
    "orbital_capture_radii": ("float64_triple", "run_float64_triple.py", 1e-12, 1e-9),
    "orbital_capture_area": ("float64_unary", "run_float64_unary.py", 1e-14, 1e-9),
}


def verify_language(language: str, elisa_compiler: str | None, build_dir: Path) -> dict:
    entries = []
    for algorithm, (family, runner_name, rel_tol, abs_tol) in ALGORITHMS.items():
        directory = build_dir / algorithm / language
        manifest = build(algorithm, language, directory,
                         compiler=elisa_compiler if language == "elisa" else None,
                         with_checker=False, family=family)
        workload_path = ROOT / "benchmarks" / "o" / algorithm / "workload.json"
        workload = json.loads(workload_path.read_text(encoding="utf-8"))
        records_path = directory / "verification-records.jsonl"
        records_path.unlink(missing_ok=True)
        completed = subprocess.run(
            [sys.executable, str(ROOT / "benchmarks" / runner_name),
             "--build-manifest", str(directory / "build.json"),
             "--samples", "1", "--warmups", "0", "--repetitions", "1",
             "--output", str(records_path)],
            cwd=ROOT, capture_output=True, text=True, timeout=180)
        if completed.returncode:
            raise RuntimeError(f"{algorithm}/{language} workload failed: {completed.stdout}\n{completed.stderr}")
        records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
        if len(records) != len(workload["cases"]):
            raise RuntimeError(f"{algorithm}/{language} emitted an unexpected record count")
        for case, record in zip(workload["cases"], records):
            observed = record["measurement"]["observed_result"]
            expected = float(case["expected_result"])
            if not math.isclose(observed, expected, rel_tol=rel_tol, abs_tol=abs_tol):
                raise RuntimeError(f"{algorithm}/{language}/{case['id']}: expected {expected!r}, observed {observed!r}")
            if (record["algorithm"] != algorithm
                    or record["implementation"]["language"] != language
                    or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                    or record["workload"]["input_values"] != case["input_values"]):
                raise RuntimeError(f"{algorithm}/{language}/{case['id']}: provenance mismatch")
        entries.append({"algorithm": algorithm, "status": "passed", "workload_records": len(records),
                        "source_sha256": manifest["source_sha256"],
                        "build_manifest": str(directory / "build.json"),
                        "build_manifest_sha256": sha256_file(directory / "build.json"),
                        "verification_records": str(records_path),
                        "verification_records_sha256": sha256_file(records_path)})
    return {"language": language, "status": "passed", "benchmarks": entries}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/orbital_capture")
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify_language, language, args.elisa_compiler, args.build_dir): language
                   for language in args.languages}
        for future in as_completed(futures):
            language = futures[future]
            try:
                results.append(future.result())
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL orbital_capture/{language}: {error}", file=sys.stderr, flush=True)
    results.sort(key=lambda item: item["language"])
    report = {"verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures and len(results) == len(args.languages),
              "language_count": len(args.languages), "results": results, "failures": failures}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "passed" if report["all_passed"] else "failed",
                      "languages": [entry["language"] for entry in results],
                      "workload_records_per_language": {entry["language"]: sum(
                          benchmark["workload_records"] for benchmark in entry["benchmarks"])
                          for entry in results},
                      "report": str(report_path)}, indent=2))
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
