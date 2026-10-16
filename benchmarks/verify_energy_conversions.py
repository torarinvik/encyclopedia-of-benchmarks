#!/usr/bin/env python3
"""Verify energy-conversion ports against a staged exact-rational oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from fractions import Fraction
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

ALGORITHM = "energy_conversions"
INVALID_RESULT = -1e300
FACTORS = (1.0, 1000.0, 1000000.0, 1000000000.0, 1.0,
           3600.0, 3600000.0, 1.0, 4186.8, 4186800.0,
           1.602176634e-19, 1055.05585, 1.355818)


def oracle(value: float, from_code: float, to_code: float) -> float:
    if (not all(math.isfinite(item) for item in (value, from_code, to_code))
            or abs(value) > 1_000_000.0
            or not from_code.is_integer() or not 0.0 <= from_code < len(FACTORS)
            or not to_code.is_integer() or not 0.0 <= to_code < len(FACTORS)):
        return INVALID_RESULT
    exact_product = Fraction.from_float(value) * Fraction.from_float(FACTORS[int(from_code)])
    rounded_product = float(exact_product)
    exact_quotient = Fraction.from_float(rounded_product) / Fraction.from_float(FACTORS[int(to_code)])
    return float(exact_quotient)


def corpus(workload: dict) -> tuple[str, int]:
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    triples: set[tuple[float, float, float]] = set()
    for case in workload["cases"]:
        value, from_code, to_code, expected = encode_case(case, tolerance, ALGORITHM)
        exact = oracle(value, from_code, to_code)
        if not matches(expected, exact, tolerance, value, from_code):
            raise ValueError(f"published workload disagrees with the exact staged oracle: {case['id']}")
        triples.add((value, from_code, to_code))

    for value in (-1_000_000.0, -123.5, -1.0, 0.0, 1.0, 123.5, 1_000_000.0):
        for from_code in range(len(FACTORS)):
            for to_code in range(len(FACTORS)):
                triples.add((value, float(from_code), float(to_code)))
    rng = random.Random(20261015)
    for _ in range(512):
        triples.add((rng.uniform(-1_000_000.0, 1_000_000.0),
                     float(rng.randrange(len(FACTORS))),
                     float(rng.randrange(len(FACTORS)))))
    triples.update(((1.0, 13.0, 0.0), (1.0, 0.0, 12.5),
                    (-1_000_000.5, 0.0, 0.0), (1_000_000.5, 0.0, 0.0)))

    lines = [f"{len(triples)}\n"]
    for value, from_code, to_code in sorted(triples):
        expected = oracle(value, from_code, to_code)
        lines.append(" ".join(format(item, ".17g") for
                              item in (value, from_code, to_code, expected, tolerance)) + "\n")
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
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
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
                or not matches(observed, expected, tolerance, value, from_code)
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
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/float64_triple/e/energy_conversions")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/e/energy_conversions/workload.json")
                          .read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("measurement", {}).get("comparison_model") != "float64_triple_call"):
        parser.error("energy_conversions workload does not match the float64_triple contract")
    data, case_count = corpus(workload)
    build_dir = args.build_dir.resolve()
    build_dir.mkdir(parents=True, exist_ok=True)
    corpus_path = build_dir / "energy_conversions-corpus.txt"
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
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages)
              and all(result["status"] == "passed" for result in results),
              "corpus_sha256": sha256_file(corpus_path),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
