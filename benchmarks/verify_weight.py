#!/usr/bin/env python3
"""Verify weight-conversion ports against an exact staged binary64 oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from fractions import Fraction
import datetime as dt
import hashlib
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_triple import (encode_case, input_scaled_tolerance_for_output,
                                matches_output_relative)

ALGORITHM = "weight"
INVALID_RESULT = -1e300

# Binary64 factors copied from the pinned Rust source, kept here independently
# of the recorder's contract table so this verifier can detect table drift.
FACTORS = (1e12, 1e9, 1000.0, 1.0, 1e-3, 1e-6, 1e-9, 1e-12, 1e-15,
           1016.0469088, 907.18474, 50.80234544, 12.70058636, 6.35029318,
           0.45359237, 0.028349523125, 0.0017718451953125, 0.00006479891,
           0.3732417216, 0.0311034768, 0.00155517384, 0.0002,
           1.66053906660e-27)


def oracle(value: float, from_code: float, to_code: float) -> float:
    if (not all(math.isfinite(item) for item in (value, from_code, to_code))
            or abs(value) > 1_000_000.0
            or not from_code.is_integer() or not 0.0 <= from_code < len(FACTORS)
            or not to_code.is_integer() or not 0.0 <= to_code < len(FACTORS)):
        return INVALID_RESULT

    # Preserve the source's two binary64 operations: round the exact product
    # back to binary64 before dividing by the target factor.
    product = float(Fraction.from_float(value) * Fraction.from_float(FACTORS[int(from_code)]))
    quotient = Fraction.from_float(product) / Fraction.from_float(FACTORS[int(to_code)])
    return float(quotient)


def corpus(workload: dict) -> tuple[str, int]:
    tolerance = float(workload["measurement"]["output_relative_tolerance"])
    triples: set[tuple[float, float, float]] = set()
    for case in workload["cases"]:
        value, from_code, to_code, expected = encode_case(case, tolerance, ALGORITHM)
        exact = oracle(value, from_code, to_code)
        if not matches_output_relative(expected, exact, tolerance):
            raise ValueError(f"published workload disagrees with the staged oracle: {case['id']}")
        triples.add((value, from_code, to_code))

    values = (-1_000_000.0, -123.5, -1.0, -1e-6, 0.0, 1e-6, 1.0, 123.5,
              1_000_000.0)
    triples.update((value, float(source), float(target))
                   for value in values for source in range(len(FACTORS))
                   for target in range(len(FACTORS)))
    rng = random.Random(20261015)
    for _ in range(512):
        triples.add((rng.uniform(-1_000_000.0, 1_000_000.0),
                     float(rng.randrange(len(FACTORS))),
                     float(rng.randrange(len(FACTORS)))))
    triples.update(((1.0, -1.0, 0.0), (1.0, 23.0, 0.0), (1.0, 2.5, 3.0),
                    (1.0, 0.0, -1.0), (1.0, 0.0, 23.0), (1.0, 3.0, 4.25),
                    (-1_000_000.5, 0.0, 0.0), (1_000_000.5, 0.0, 0.0)))

    lines = [f"{len(triples)}\n"]
    for value, from_code, to_code in sorted(triples):
        expected = oracle(value, from_code, to_code)
        checker_tolerance = input_scaled_tolerance_for_output(
            tolerance, expected, value, from_code)
        lines.append(" ".join(format(item, ".17g") for
                              item in (value, from_code, to_code, expected, checker_tolerance)) + "\n")
    return "".join(lines), len(triples)


def verify(language: str, build_dir: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, build_dir,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_triple")
    checker = manifest["binaries"]["float64_triple_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64 C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = build_dir / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_float64_triple.py"),
         "--build-manifest", str(build_dir / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    tolerance = float(workload["measurement"]["output_relative_tolerance"])
    for case, record in zip(workload["cases"], records):
        value, from_code, to_code, expected = encode_case(case, tolerance, ALGORITHM)
        observed = record["measurement"]["observed_result"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] is not None
                or record["workload"]["input_values"] != [value, from_code, to_code]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "float64_triple_call"
                or record["measurement"].get("result_output_relative_tolerance") != tolerance
                or not matches_output_relative(observed, expected, tolerance)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(build_dir / "build.json"),
            "build_manifest_sha256": sha256_file(build_dir / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_triple/weight")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    workload_path = ROOT / "benchmarks/w/weight/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("measurement", {}).get("comparison_model") != "float64_triple_call"):
        parser.error("weight workload does not match the float64_triple contract")
    data, case_count = corpus(workload)
    build_dir = args.build_dir.resolve()
    build_dir.mkdir(parents=True, exist_ok=True)
    corpus_path = build_dir / "weight-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, build_dir / language,
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
              "platform": platform.platform(), "workload_sha256": sha256_file(workload_path),
              "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
