#!/usr/bin/env python3
"""Check float64-triple ports against their bounded oracles."""

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
from coordinate_converter_oracle import expected_result as coordinate_converter_oracle
from rectangular_to_polar_oracle import expected_result as rectangular_to_polar_oracle
from run_float64_triple import encode_case, matches
from standard_score_oracle import expected_result as standard_score_oracle
from dual_number_automatic_differentiation_oracle import expected_result as dual_number_ad_oracle

ALGORITHMS = ("lerp", "standard_score", "coordinate_converter", "rectangular_to_polar",
              "dual_number_automatic_differentiation")


def oracle(start: float, end: float, t: float) -> float:
    if (not all(math.isfinite(value) for value in (start, end, t))
            or abs(start) > 1e12 or abs(end) > 1e12 or not 0.0 <= t <= 1.0):
        raise ValueError("lerp inputs must be finite, bounded, and have t in [0, 1]")
    with localcontext() as context:
        context.prec = 100
        a, b, amount = map(Decimal.from_float, (start, end, t))
        return float(a + amount * (b - a))


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    triples: set[tuple[float, float, float]] = set()
    for case in workload["cases"]:
        start, end, t, expected = encode_case(case, tolerance, algorithm)
        if algorithm == "lerp":
            exact = oracle(start, end, t)
            if not matches(expected, exact, tolerance, start, end):
                raise ValueError(f"published workload disagrees with the high-precision oracle: {case['id']}")
        elif algorithm == "coordinate_converter":
            exact = coordinate_converter_oracle([start, end, t])
            if not matches(expected, exact, tolerance, start, end):
                raise ValueError(f"published workload disagrees with the coordinate oracle: {case['id']}")
        elif algorithm == "rectangular_to_polar":
            exact = rectangular_to_polar_oracle([start, end, t])
            if (expected != exact
                    or (expected == 0.0 and math.copysign(1.0, expected) != math.copysign(1.0, exact))):
                raise ValueError(f"published workload disagrees with the Rust-rounded polar oracle: {case['id']}")
        elif algorithm == "dual_number_automatic_differentiation":
            exact = dual_number_ad_oracle(start, end, t)
            if not matches(expected, exact, tolerance, start, end):
                raise ValueError(f"published workload disagrees with the dual-number oracle: {case['id']}")
        triples.add((start, end, t))

    if algorithm == "lerp":
        endpoints = [-1e12, -100.0, -1.0, 0.0, 1.0, 100.0, 1e12]
        parameters = [0.0, 0.125, 0.25, 0.5, 0.75, 0.875, 1.0]
        triples.update((start, end, t) for start in endpoints for end in endpoints for t in parameters)
        rng = random.Random(20261014)
        for _ in range(512):
            triples.add((rng.uniform(-1e12, 1e12), rng.uniform(-1e12, 1e12), rng.random()))
    elif algorithm == "standard_score":
        values = [-1_000_000.0, -1.0, 0.0, 1.0, 1_000_000.0]
        deviations = [-1_000_000.0, -1.0, -0.000001, 0.000001, 1.0, 1_000_000.0]
        triples.update((value, mean, deviation)
                       for value in values for mean in values for deviation in deviations)
        triples.update(((1.0, 0.0, 0.0), (1_000_001.0, 0.0, 1.0),
                        (-1_000_001.0, 0.0, 1.0), (0.0, 0.0, 1_000_001.0)))
    elif algorithm == "coordinate_converter":
        cartesian_bounds = (-1_000_000.0, -1.0, 0.0, 1.0, 1_000_000.0)
        for selector in (0.0, 1.0):
            triples.update((x, y, selector) for x in cartesian_bounds for y in cartesian_bounds)
        radii = (0.0, 1e-12, 1.0, 10_000.0, 1_000_000.0)
        angles = (-36_000.0, -360.0, -180.0, -90.0, -45.0, 0.0,
                  45.0, 90.0, 180.0, 360.0, 36_000.0)
        for selector in (2.0, 3.0):
            triples.update((radius, angle, selector) for radius in radii for angle in angles)
        rng = random.Random(20261016)
        for _ in range(256):
            if rng.randrange(2) == 0:
                triples.add((rng.uniform(-1_000_000.0, 1_000_000.0),
                             rng.uniform(-1_000_000.0, 1_000_000.0),
                             float(rng.randrange(2))))
            else:
                triples.add((rng.uniform(0.0, 1_000_000.0),
                             rng.uniform(-36_000.0, 36_000.0),
                             float(rng.randrange(2, 4))))
        triples.update((1.0, 1.0, selector) for selector in (-1.0, 1.5, 4.0))
        triples.update((x, 0.0, selector) for x, selector in
                       ((-1_000_001.0, 0.0), (1_000_001.0, 1.0),
                        (-0.1, 2.0), (1_000_001.0, 3.0)))
        triples.update((1.0, angle, selector) for angle, selector in
                       ((-36_001.0, 2.0), (36_001.0, 3.0)))
    elif algorithm == "rectangular_to_polar":
        coordinate_bounds = (-1_000_000.0, -1.0, 0.0, 1.0, 1_000_000.0)
        triples.update((real, imag, selector)
                       for selector in (0.0, 1.0)
                       for real in coordinate_bounds for imag in coordinate_bounds)
        rng = random.Random(20261016)
        for _ in range(256):
            triples.add((rng.uniform(-1_000_000.0, 1_000_000.0),
                         rng.uniform(-1_000_000.0, 1_000_000.0),
                         float(rng.randrange(2))))
        triples.update((real, imag, selector) for real, imag, selector in (
            (1_000_001.0, 0.0, 0.0), (-1_000_001.0, 0.0, 1.0),
            (0.0, 1_000_001.0, 0.0), (0.0, -1_000_001.0, 1.0),
            (1.0, 0.0, -1.0), (1.0, 0.0, 1.5), (1.0, 0.0, 2.0),
        ))
    elif algorithm == "dual_number_automatic_differentiation":
        positions = (-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0)
        triples.update((position, float(power), float(order))
                       for position in positions for power in range(9) for order in range(power + 1))
        rng = random.Random(20261016)
        for _ in range(256):
            power = rng.randrange(9)
            triples.add((rng.uniform(-1.0, 1.0), float(power), float(rng.randrange(power + 1))))
        triples.update(((1.5, 2.0, 1.0), (0.5, 3.5, 1.0), (0.5, 3.0, 4.0), (0.5, 3.0, -1.0)))
    else:
        raise ValueError(f"unsupported float64_triple algorithm: {algorithm}")

    # A Python set merges +0.0 and -0.0, so keep signed-zero probes as explicit
    # rows for this source, whose atan2 behavior distinguishes their signs.
    signed_zero_cases = (
        (1.0, -0.0, 1.0),
        (-0.0, 0.0, 1.0),
        (0.0, -0.0, 1.0),
        (-0.0, -0.0, 1.0),
    ) if algorithm == "rectangular_to_polar" else ()
    lines = [str(len(triples) + len(signed_zero_cases)) + "\n"]
    for start, end, t in sorted(triples):
        expected = (oracle(start, end, t) if algorithm == "lerp" else
                    standard_score_oracle(start, end, t) if algorithm == "standard_score" else
                    coordinate_converter_oracle([start, end, t]) if algorithm == "coordinate_converter" else
                    rectangular_to_polar_oracle([start, end, t]) if algorithm == "rectangular_to_polar" else
                    dual_number_ad_oracle(start, end, t))
        lines.append(" ".join(format(value, ".17g") for value in
                              (start, end, t, expected, tolerance)) + "\n")
    for start, end, t in signed_zero_cases:
        expected = rectangular_to_polar_oracle([start, end, t])
        lines.append(" ".join(format(value, ".17g") for value in
                              (start, end, t, expected, tolerance)) + "\n")
    return "".join(lines), len(triples) + len(signed_zero_cases)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
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
        start, end, t, expected = encode_case(case, tolerance, algorithm)
        observed = record["measurement"]["observed_result"]
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] is not None
                or record["workload"]["input_values"] != [start, end, t]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "float64_triple_call"
                or not matches(observed, expected, tolerance, start, end)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, default="lerp")
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_triple")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload_path = ROOT / "benchmarks" / args.algorithm[0] / args.algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload, args.algorithm)
    (directory / f"{args.algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, args.algorithm, language, directory / args.algorithm / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {args.algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {args.algorithm}/{language}: {case_count} oracle triples, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": args.algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = (directory / "verification.json" if args.algorithm == "lerp"
                   else directory / f"{args.algorithm}-verification.json")
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
