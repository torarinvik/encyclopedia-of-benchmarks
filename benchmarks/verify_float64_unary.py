#!/usr/bin/env python3
"""Check float64 unary packages with an independent oracle and C ABI checker."""

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
from fast_inverse_sqrt_cpp_oracle import MAX_VALUE as FAST_INVERSE_SQRT_CPP_MAX_VALUE
from fast_inverse_sqrt_cpp_oracle import MIN_VALUE as FAST_INVERSE_SQRT_CPP_MIN_VALUE
from fast_inverse_sqrt_cpp_oracle import expected_result as fast_inverse_sqrt_cpp_oracle
from gauss_legendre_oracle import MAX_ITERATIONS as MAX_GAUSS_LEGENDRE_ITERATIONS
from gauss_legendre_oracle import expected_result as gauss_legendre_oracle
from run_float64_unary import encode_case

ALGORITHMS = ("problem58", "problem207", "problem587", "gamma", "gauss_legendre", "fast_inverse_sqrt_cpp")


def is_prime(value: int) -> bool:
    """Deterministic Miller-Rabin for the bounded spiral corners (< 2^32)."""
    if value < 2:
        return False
    for small in (2, 3, 5, 7, 11):
        if value % small == 0:
            return value == small
    odd_part, power = value - 1, 0
    while odd_part % 2 == 0:
        odd_part //= 2
        power += 1
    for base in (2, 3, 5, 7, 11):
        witness = pow(base, odd_part, value)
        if witness in (1, value - 1):
            continue
        for _ in range(power - 1):
            witness = witness * witness % value
            if witness == value - 1:
                break
        else:
            return False
    return True


def problem58_oracle(ratio: float) -> float:
    if not math.isfinite(ratio) or not 0.1 <= ratio <= 0.6:
        return -1.0
    side, prime_count = 3, 3
    while prime_count / (2 * side - 1) >= ratio:
        square, step = side * side, side + 1
        prime_count += sum(is_prime(square + corner * step) for corner in (1, 2, 3))
        side += 2
    return float(side)


def problem207_oracle(max_proportion: float) -> float:
    """Find the first qualifying partition by searching perfect-count intervals."""
    if not math.isfinite(max_proportion) or not 1e-5 <= max_proportion <= 1.0:
        return -1e300
    maximum_partitions = 5_000_000
    perfect_count = 1
    while True:
        low = (1 << perfect_count) - 1
        high = min((1 << (perfect_count + 1)) - 2, maximum_partitions)
        if low > maximum_partitions:
            return -1e300
        if float(perfect_count) / float(low) < max_proportion:
            result = low
        elif float(perfect_count) / float(high) >= max_proportion:
            perfect_count += 1
            continue
        else:
            left, right = low + 1, high
            while left < right:
                middle = (left + right) // 2
                if float(perfect_count) / float(middle) < max_proportion:
                    right = middle
                else:
                    left = middle + 1
            result = left
        return float(result * (result + 1))


def problem587_ratio(circles_number: int) -> float:
    """Return the concave-triangle to L-section area ratio."""
    intersection_y = (circles_number + 1 - math.sqrt(2 * circles_number)) / (
        2 * (circles_number**2 + 1))
    intersection_x = circles_number * intersection_y

    def bottom_arc(point: float) -> float:
        return ((1 - 2 * point) * math.sqrt(point - point**2)
                + 2 * point + math.asin(math.sqrt(1 - point))) / 4

    triangle = intersection_x * intersection_y / 2
    concave_region = bottom_arc(0.5) - bottom_arc(intersection_x)
    l_section_area = (1 - math.pi / 4) / 4
    return (triangle + concave_region) / l_section_area


def problem587_oracle(fraction: float) -> float:
    """Binary-search the decreasing geometric ratio for the first qualifying n."""
    if not math.isfinite(fraction) or not 0.001 <= fraction <= 0.1:
        return -1e300
    low, high = 1, 100_000
    if problem587_ratio(high) >= fraction:
        return -1e300
    while low < high:
        middle = (low + high) // 2
        if problem587_ratio(middle) < fraction:
            high = middle
        else:
            low = middle + 1
    return float(low)


def oracle(algorithm: str, value: float) -> float:
    if algorithm == "problem58":
        return problem58_oracle(value)
    if algorithm == "problem207":
        return problem207_oracle(value)
    if algorithm == "problem587":
        return problem587_oracle(value)
    if algorithm == "gamma":
        if (not math.isfinite(value) or not 0.5 <= value <= 20.0
                or not (value * 2.0).is_integer()):
            return -1e300
        return math.gamma(value)
    if algorithm == "gauss_legendre":
        return gauss_legendre_oracle([value])
    if algorithm == "fast_inverse_sqrt_cpp":
        return fast_inverse_sqrt_cpp_oracle(value)
    raise ValueError(f"no oracle for {algorithm}")


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    measurement = workload["measurement"]
    relative = float(measurement["relative_tolerance"])
    absolute = float(measurement.get("absolute_tolerance", 0.0))
    values = {float(case["input_values"][0]) for case in workload["cases"]}
    rng = random.Random(20261014)
    if algorithm == "problem58":
        values.update((0.1, 0.10000000000000002, 0.111, 0.2, 0.5, 0.6,
                       0.09999999999999999, 0.6000000000000001))
        values.update(rng.uniform(0.1, 0.6) for _ in range(16))
    elif algorithm == "problem207":
        values.update((1e-5, math.nextafter(1e-5, math.inf),
                       math.nextafter(1e-5, -math.inf), 0.1, 0.5, 1.0,
                       math.nextafter(1.0, math.inf)))
        values.update(rng.uniform(1e-5, 1.0) for _ in range(16))
    elif algorithm == "problem587":
        values.update((0.001, math.nextafter(0.001, math.inf),
                       math.nextafter(0.001, -math.inf), 0.01, 0.05, 0.1,
                       math.nextafter(0.1, math.inf)))
        values.update(rng.uniform(0.001, 0.1) for _ in range(16))
    elif algorithm == "gamma":
        values.update((0.5, 1.0, 1.5, 2.0, 19.5, 20.0,
                       math.nextafter(0.5, -math.inf),
                       math.nextafter(20.0, math.inf),
                       0.0, -0.5, 0.75, 1.25))
        values.update(rng.randint(1, 40) / 2.0 for _ in range(16))
    elif algorithm == "gauss_legendre":
        values.update((-1.0, math.nextafter(0.0, -math.inf), 0.0, 0.5,
                       1.0, 2.0, 3.0, float(MAX_GAUSS_LEGENDRE_ITERATIONS),
                       math.nextafter(float(MAX_GAUSS_LEGENDRE_ITERATIONS), math.inf),
                       float(MAX_GAUSS_LEGENDRE_ITERATIONS + 1)))
        values.update(float(rng.randint(0, MAX_GAUSS_LEGENDRE_ITERATIONS)) for _ in range(16))
        values.update(rng.randint(0, MAX_GAUSS_LEGENDRE_ITERATIONS) + 0.5 for _ in range(8))
    elif algorithm == "fast_inverse_sqrt_cpp":
        values.update((
            FAST_INVERSE_SQRT_CPP_MIN_VALUE,
            math.nextafter(FAST_INVERSE_SQRT_CPP_MIN_VALUE, -math.inf),
            math.nextafter(FAST_INVERSE_SQRT_CPP_MIN_VALUE, math.inf),
            -1.0, 0.0, 1.0, 2.0, 0.5, 12.0, 123.456,
            FAST_INVERSE_SQRT_CPP_MAX_VALUE,
            math.nextafter(FAST_INVERSE_SQRT_CPP_MAX_VALUE, math.inf),
        ))
        values.update(rng.uniform(FAST_INVERSE_SQRT_CPP_MIN_VALUE,
                                  FAST_INVERSE_SQRT_CPP_MAX_VALUE)
                      for _ in range(16))
    else:
        raise ValueError(f"no corpus for {algorithm}")
    lines = [f"{len(values)}\n"]
    for value in sorted(values):
        expected = oracle(algorithm, value)
        lines.append(" ".join(format(item, ".17g") for item in
                              (value, expected, relative, absolute)) + "\n")
    return "".join(lines), len(values)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_unary")
    checker = manifest["binaries"]["float64_unary_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64 unary C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_float64_unary.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                               text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    relative = float(workload["measurement"]["relative_tolerance"])
    absolute = float(workload["measurement"].get("absolute_tolerance", 0.0))
    for case, record in zip(workload["cases"], records):
        value, expected = encode_case(case, algorithm, absolute, relative)
        observed = record["measurement"]["observed_result"]
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [value]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["comparison_model"] != "float64_unary_call"
                or not math.isfinite(observed)
                or abs(observed - expected) > absolute + relative * abs(expected)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, default="problem58")
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_unary")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    algorithm = args.algorithm
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload = json.loads((ROOT / "benchmarks" / letter / algorithm / "workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload, algorithm)
    (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, algorithm, language, directory / algorithm / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": algorithm, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = (directory / "verification.json" if algorithm == "problem58"
                   else directory / f"{algorithm}-verification.json")
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
