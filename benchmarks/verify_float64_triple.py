#!/usr/bin/env python3
"""Check lerp ports against a high-precision oracle over binary64 inputs."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from decimal import Decimal, localcontext
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_triple import encode_case, matches

ALGORITHM = "lerp"


def oracle(start: float, end: float, t: float) -> float:
    if (not all(math.isfinite(value) for value in (start, end, t))
            or abs(start) > 1e12 or abs(end) > 1e12 or not 0.0 <= t <= 1.0):
        raise ValueError("lerp inputs must be finite, bounded, and have t in [0, 1]")
    with localcontext() as context:
        context.prec = 100
        a, b, amount = map(Decimal.from_float, (start, end, t))
        return float(a + amount * (b - a))


def corpus(workload: dict) -> tuple[str, int]:
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    triples = set()
    for case in workload["cases"]:
        start, end, t, expected = encode_case(case, tolerance)
        exact = oracle(start, end, t)
        if not matches(expected, exact, tolerance, start, end):
            raise ValueError(f"published workload disagrees with the high-precision oracle: {case['id']}")
        triples.add((start, end, t))
    endpoints = [-1e12, -100.0, -1.0, 0.0, 1.0, 100.0, 1e12]
    parameters = [0.0, 0.125, 0.25, 0.5, 0.75, 0.875, 1.0]
    triples.update((start, end, t) for start in endpoints for end in endpoints for t in parameters)
    rng = random.Random(20261014)
    for _ in range(512):
        start = rng.uniform(-1e12, 1e12)
        end = rng.uniform(-1e12, 1e12)
        t = rng.random()
        triples.add((start, end, t))
    lines = [str(len(triples)) + "\n"]
    for start, end, t in sorted(triples):
        expected = oracle(start, end, t)
        lines.append(" ".join(format(value, ".17g") for value in
                              (start, end, t, expected, tolerance)) + "\n")
    return "".join(lines), len(triples)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_triple")
    checker = manifest["binaries"]["float64_triple_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64 C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_float64_triple.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    for case, record in zip(workload["cases"], records):
        start, end, t, expected = encode_case(case, tolerance)
        observed = record["measurement"]["observed_result"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] is not None
                or record["workload"]["input_values"] != [start, end, t]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "float64_triple_call"
                or not matches(observed, expected, tolerance, start, end)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_triple")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/l/lerp/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "lerp-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle triples, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
