#!/usr/bin/env python3
"""Verify circle ports through the float64_pair ABI."""

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
from circle_oracle import expected_result as circle_oracle
from run_float64_pair import encode_case, matches

ALGORITHM = "circle"
INVALID = -1e300


def corpus(workload: dict) -> tuple[str, int]:
    relative = float(workload["measurement"]["relative_tolerance"])
    absolute = float(workload["measurement"].get("absolute_tolerance", 0.0))
    cases: dict[tuple[float, float], float] = {}
    for case in workload["cases"]:
        first, second, expected = encode_case(case, relative, ALGORITHM, absolute)
        exact = circle_oracle(first, second)
        if not matches(expected, exact, relative, first, second, absolute):
            raise ValueError(f"workload disagrees with independent circle oracle: {case['id']}")
        cases[(first, second)] = exact
    input_scale = lambda pair: max(1.0, abs(pair[0]), abs(pair[1]))
    lines = [f"{len(cases)}\n"]
    for pair, expected in sorted(cases.items()):
        tolerance = max(relative, absolute / input_scale(pair))
        lines.append(" ".join(format(value, ".17g") for value in
                              (pair[0], pair[1], expected, tolerance)) + "\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_pair")
    checker = manifest["binaries"]["float64_pair_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"float64_pair C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_float64_pair.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    relative = float(workload["measurement"]["relative_tolerance"])
    absolute = float(workload["measurement"].get("absolute_tolerance", 0.0))
    for case, record in zip(workload["cases"], records):
        first, second, expected = encode_case(case, relative, ALGORITHM, absolute)
        observed = float(record["measurement"]["observed_result"])
        oracle_result = circle_oracle(first, second)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [first, second]
                or record["workload"]["expected_result"] != expected
                or not matches(observed, oracle_result, relative, first, second, absolute)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_pair/circle")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/c/circle/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "circle-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle pairs", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
