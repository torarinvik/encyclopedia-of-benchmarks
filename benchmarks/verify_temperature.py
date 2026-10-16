#!/usr/bin/env python3
"""Verify all temperature-scale ports against an exact-rational oracle."""

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

ALGORITHM = "temperature"
INVALID_RESULT = -1e300


def to_kelvin(value: Fraction, unit: int) -> Fraction:
    if unit == 0:
        return value
    if unit == 1:
        return value + Fraction(27315, 100)
    if unit == 2:
        return (value + Fraction(45967, 100)) * 5 / 9
    if unit == 3:
        return value * 5 / 9
    if unit == 4:
        return Fraction(37315, 100) - value * 2 / 3
    if unit == 5:
        return value * 100 / 33 + Fraction(27315, 100)
    if unit == 6:
        return value * 5 / 4 + Fraction(27315, 100)
    return (value - Fraction(15, 2)) * 40 / 21 + Fraction(27315, 100)


def from_kelvin(kelvin: Fraction, unit: int) -> Fraction:
    if unit == 0:
        return kelvin
    if unit == 1:
        return kelvin - Fraction(27315, 100)
    if unit == 2:
        return kelvin * 9 / 5 - Fraction(45967, 100)
    if unit == 3:
        return kelvin * 9 / 5
    if unit == 4:
        return (Fraction(37315, 100) - kelvin) * 3 / 2
    if unit == 5:
        return (kelvin - Fraction(27315, 100)) * 33 / 100
    if unit == 6:
        return (kelvin - Fraction(27315, 100)) * 4 / 5
    return (kelvin - Fraction(27315, 100)) * 21 / 40 + Fraction(15, 2)


def oracle(value: float, from_code: float, to_code: float) -> float:
    if (not all(math.isfinite(item) for item in (value, from_code, to_code))
            or abs(value) > 1_000_000.0
            or not from_code.is_integer() or not 0.0 <= from_code <= 7.0
            or not to_code.is_integer() or not 0.0 <= to_code <= 7.0):
        return INVALID_RESULT
    exact_value = Fraction.from_float(value)
    kelvin = to_kelvin(exact_value, int(from_code))
    return float(from_kelvin(kelvin, int(to_code)))


def corpus(workload: dict) -> tuple[str, int]:
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    triples = set()
    for case in workload["cases"]:
        value, from_code, to_code, expected = encode_case(case, tolerance, ALGORITHM)
        exact = oracle(value, from_code, to_code)
        if not matches(expected, exact, tolerance, value, from_code):
            raise ValueError(f"published workload disagrees with the exact-rational oracle: {case['id']}")
        triples.add((value, from_code, to_code))

    values = (-1_000_000.0, -459.67, -273.15, -40.0, -1.0, 0.0,
              32.0, 100.0, 273.15, 1_000_000.0)
    triples.update((value, float(source), float(target))
                   for value in values for source in range(8) for target in range(8))
    rng = random.Random(20261015)
    for _ in range(512):
        triples.add((rng.uniform(-1_000_000.0, 1_000_000.0),
                     float(rng.randrange(8)), float(rng.randrange(8))))

    lines = [str(len(triples)) + "\n"]
    for value, from_code, to_code in sorted(triples):
        expected = oracle(value, from_code, to_code)
        lines.append(" ".join(format(item, ".17g") for item in
                              (value, from_code, to_code, expected, tolerance)) + "\n")
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
        raise RuntimeError("recorder emitted an unexpected number of records")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_triple/temperature")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    build_dir = args.build_dir.resolve()
    build_dir.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/t/temperature/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (build_dir / "temperature-corpus.txt").write_text(data, encoding="utf-8")
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
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
