#!/usr/bin/env python3
"""Verify YIN ports against the pinned source-order oracle."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from yin_oracle import INVALID_RESULT, expected_result
from run_i64_array_float64 import encode_case, resolve_tolerances, result_matches

ALGORITHM = "yin"
WORKLOAD_PATH = ROOT / "benchmarks/y/yin/workload.json"


def corpus(workload: dict) -> tuple[list[tuple[int, ...]], float, float]:
    abs_tol, rel_tol = resolve_tolerances(workload)
    cases = {tuple(case["input_values"]) for case in workload["cases"]}
    rng = random.Random(0x71A2026)
    for count in (32, 64, 128, 256):
        for period in (4, 5, 8, 11, 16, 24, 32):
            if period >= count:
                continue
            sr = 1024
            min_hz = max(1, sr // min(64, period * 2))
            max_hz = min(sr // 2, sr // max(1, period // 2))
            values = [count, sr, min_hz, max_hz, rng.choice((10_000, 50_000, 100_000, 250_000))]
            values.extend(round(2000 * math.sin(2 * math.pi * i / period)) for i in range(count))
            cases.add(tuple(values))
    cases.update((
        (), (1,), (2,), (2, 100, 1, 2, 100000, 0, 1),
        (2, 100, 1, 50, 100000, 0, 1),
        (2, 100, 1, 50, 0, 0, 1),
        (2, 100, 1, 50, 1000000, 0, 1),
        (2, 100, 1, 50, 100000, 32768, 0),
        (2, 100, 1, 50, 100000, 0),
        (2, 100, 1, 50, 100000, 0, 0, 0),
        (2, 192001, 1, 20, 100000, 0, 1),
        (2, 100, 50, 51, 100000, 0, 1),
        (2, 100, 1, 100, 100000, 0, 1),
        (64, 1024, 32, 256, 100000, *([0] * 64)),
    ))
    for case in workload["cases"]:
        values, declared = encode_case(case, ALGORITHM)
        actual = expected_result(values)
        if not result_matches(declared, actual, abs_tol, rel_tol):
            raise ValueError(f"workload disagrees with YIN oracle: {case['id']}")
    return sorted(cases), abs_tol, rel_tol


def verify(language: str, directory: Path, compiler: str | None,
           cases: list[tuple[int, ...]], workload: dict,
           abs_tol: float, rel_tol: float) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=compiler if language == "elisa" else None,
                     family="i64_array_float64")
    runner = Path(manifest["binaries"]["i64_array_float64_runner"]["path"])
    for values in cases:
        expected = expected_result(values)
        command = [str(runner), str(len(values)), *map(str, values), repr(expected),
                   repr(abs_tol), repr(rel_tol), "1", "0", "1"]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=30)
        if completed.returncode:
            raise RuntimeError(f"{language} mismatch for {values}: {completed.stderr}")
        observed = float(json.loads(completed.stdout)["observed_result"])
        if not result_matches(observed, expected, abs_tol, rel_tol):
            raise RuntimeError(f"{language} differs from YIN oracle for {values}: {observed} != {expected}")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_float64.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        expected = expected_result(case["input_values"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["measurement"]["comparison_model"] != "i64_array_float64_call"
                or record["workload"]["input_values"] != case["input_values"]
                or not result_matches(record["workload"]["expected_result"], expected, abs_tol, rel_tol)
                or not result_matches(record["measurement"]["observed_result"], expected, abs_tol, rel_tol)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": len(cases), "workload_records": len(records),
            "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_float64/yin")
    parser.add_argument("--jobs", type=int, default=1)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    cases, abs_tol, rel_tol = corpus(workload)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, args.build_dir / language,
                                   args.elisa_compiler, cases, workload, abs_tol, rel_tol): language
                   for language in args.languages}
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda result: result["language"])
    report = {"schema_version": 1, "algorithm": ALGORITHM, "status": "passed",
              "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "oracle_case_count": len(cases),
              "workload_case_count": len(workload["cases"]), "results": results}
    encoded = json.dumps(report, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    print(encoded, end="")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
