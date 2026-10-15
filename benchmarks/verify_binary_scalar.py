#!/usr/bin/env python3
"""Check two-input scalar ports through their C ABI and workload recorder."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_binary_scalar import encode_values

U64_MAX = 2**64 - 1
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
ALGORITHMS = ("hamming_distance", "gcd", "lcm", "addition_without_arithmetic", "amicable_number", "ackermann", "range_bitwise_and", "first_bad_version")


def oracle(left: int, right: int) -> int:
    if type(left) is not int or type(right) is not int or not 0 <= left <= U64_MAX or not 0 <= right <= U64_MAX:
        raise ValueError("inputs must be unsigned 64-bit integers")
    return format(left ^ right, "064b").count("1")


def gcd_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= I64_MAX or not 0 <= right <= I64_MAX):
        raise ValueError("gcd inputs must be nonnegative signed 64-bit integers")
    if left == 0:
        return right
    if right == 0:
        return left
    common_shifts = 0
    while (left & 1) == 0 and (right & 1) == 0:
        left >>= 1
        right >>= 1
        common_shifts += 1
    while (left & 1) == 0:
        left >>= 1
    while right != 0:
        while (right & 1) == 0:
            right >>= 1
        if left > right:
            left, right = right, left
        right -= left
    return left << common_shifts


def lcm_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= I64_MAX or not 0 <= right <= I64_MAX):
        raise ValueError("lcm inputs must be nonnegative signed 64-bit integers")
    if left == 0 or right == 0:
        return 0
    value = (left // gcd_oracle(left, right)) * right
    return value if value <= I64_MAX else -1


def addition_without_arithmetic_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not I32_MIN <= left <= I32_MAX or not I32_MIN <= right <= I32_MAX):
        return -1
    total = left + right
    return total if I32_MIN <= total <= I32_MAX else -1


def range_bitwise_and_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= right <= I32_MAX):
        return -1
    shift = 0
    while left != right:
        left >>= 1
        right >>= 1
        shift += 1
    return left << shift


def first_bad_version_oracle(version_count: int, first_bad: int) -> int:
    if (type(version_count) is not int or type(first_bad) is not int
            or not 1 <= version_count <= I32_MAX
            or not 1 <= first_bad <= version_count):
        return -1
    return first_bad


@lru_cache(maxsize=None)
def proper_divisor_sum_oracle(number: int) -> int:
    """Use the multiplicative divisor-sum identity, independent of divisor-pair scans."""
    if number <= 1:
        return 0
    remaining, sigma, factor = number, 1, 2
    while factor <= remaining // factor:
        if remaining % factor == 0:
            prime_power, term = 1, 1
            while remaining % factor == 0:
                remaining //= factor
                prime_power *= factor
                term += prime_power
            sigma *= term
        factor = 3 if factor == 2 else factor + 2
    if remaining > 1:
        sigma *= remaining + 1
    return sigma - number


def amicable_number_oracle(left: int, right: int) -> int:
    limit = 1_000_000_000
    if (type(left) is not int or type(right) is not int
            or not 1 <= left <= limit or not 1 <= right <= limit):
        return -1
    if left == right:
        return 0
    return int(proper_divisor_sum_oracle(left) == right
               and proper_divisor_sum_oracle(right) == left)


@lru_cache(maxsize=None)
def _ackermann_value(m: int, n: int) -> int:
    if m == 0:
        return n + 1
    if n == 0:
        return _ackermann_value(m - 1, 1)
    return _ackermann_value(m - 1, _ackermann_value(m, n - 1))


def ackermann_oracle(m: int, n: int) -> int:
    if (type(m) is not int or type(n) is not int
            or not I64_MIN <= m <= I64_MAX or not I64_MIN <= n <= I64_MAX
            or not 0 <= m <= 3 or not 0 <= n <= 5):
        return -1
    return _ackermann_value(m, n)


def result(algorithm: str, left: int, right: int) -> int:
    if algorithm == "hamming_distance":
        return oracle(left, right)
    if algorithm == "gcd":
        return gcd_oracle(left, right)
    if algorithm == "lcm":
        return lcm_oracle(left, right)
    if algorithm == "addition_without_arithmetic":
        return addition_without_arithmetic_oracle(left, right)
    if algorithm == "amicable_number":
        return amicable_number_oracle(left, right)
    if algorithm == "ackermann":
        return ackermann_oracle(left, right)
    if algorithm == "range_bitwise_and":
        return range_bitwise_and_oracle(left, right)
    if algorithm == "first_bad_version":
        return first_bad_version_oracle(left, right)
    raise ValueError(f"no independent oracle for {algorithm}")


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    pairs = {tuple(case["input_values"]) for case in workload["cases"]}
    if algorithm == "ackermann":
        pairs.update((m, n) for m in range(4) for n in range(6))
        left_edges = [I64_MIN, -1, 0, 1, 3, 4, I64_MAX]
        right_edges = [I64_MIN, -1, 0, 1, 5, 6, I64_MAX]
        pairs.update((left, right) for left in left_edges for right in right_edges)
        rng = random.Random(20261014)
        pairs.update((rng.randrange(-1, 5), rng.randrange(-1, 7)) for _ in range(512))
    elif algorithm == "range_bitwise_and":
        pairs.update((left, right) for left in range(256) for right in range(256))
        edge_values = sorted({0, 1, 2, 3, 7, 8, 15, 16, 31, 32, 63, 64,
                              127, 128, 255, 256, 1023, 1024,
                              *(2**bit + delta for bit in range(1, 31) for delta in (-1, 0, 1)),
                              I32_MAX - 2, I32_MAX - 1, I32_MAX, I32_MAX + 1})
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261015)
        for _ in range(1024):
            left = rng.randrange(0, I32_MAX + 2)
            right = rng.randrange(0, I32_MAX + 2)
            pairs.add((min(left, right), max(left, right)))
            pairs.add((left, right))
    elif algorithm == "first_bad_version":
        pairs = set()
        for version_count in range(1, 129):
            pairs.update((version_count, first_bad)
                         for first_bad in range(1, version_count + 1))
            pairs.add((version_count, 0))
            pairs.add((version_count, version_count + 1))
        edge_counts = [1, 2, 3, 4, 7, 8, 2**30 - 1, 2**30,
                       I32_MAX - 1, I32_MAX, I32_MAX + 1, U64_MAX]
        for version_count in edge_counts:
            edge_bad_values = {0, 1, 2, version_count // 2,
                               version_count // 2 + 1, version_count,
                               version_count + 1, U64_MAX}
            edge_bad_values = {value for value in edge_bad_values if value <= U64_MAX}
            pairs.update((version_count, first_bad) for first_bad in edge_bad_values)
    else:
        pairs.update((left, right) for left in range(256) for right in range(256))
    if algorithm != "ackermann":
        if algorithm == "range_bitwise_and":
            edge_values = [0, 1, 2, 3, 7, 8, 15, 16, 2**30 - 1, 2**30,
                           I32_MAX - 1, I32_MAX, I32_MAX + 1, U64_MAX]
            random_bits = 32
        elif algorithm == "first_bad_version":
            edge_values = [0, 1, 2, 3, I32_MAX - 1, I32_MAX, I32_MAX + 1, U64_MAX]
            random_bits = 32
        elif algorithm == "hamming_distance":
            edge_values = [0, 1, 2**63, U64_MAX, 0xAAAAAAAAAAAAAAAA, 0x5555555555555555]
            random_bits = 64
        elif algorithm == "addition_without_arithmetic":
            edge_values = [I32_MIN - 1, I32_MIN, I32_MIN + 1, -1, 0, 1,
                           I32_MAX - 1, I32_MAX, I32_MAX + 1]
            random_bits = 32
        elif algorithm == "amicable_number":
            edge_values = [0, 1, 2, 3, 6, 28, 220, 284, 1184, 1210,
                           2620, 2924, 5020, 5564, 6232, 6368,
                           999_999, 1_000_000, 999_999_999, 1_000_000_000,
                           1_000_000_001]
            random_bits = 30
        else:
            edge_values = [0, 1, 2, 3, I64_MAX, I64_MAX - 1, 7540113804746346429, 4660046610375530309]
            random_bits = 63
        pairs.update((left, right) for left in edge_values for right in edge_values)
        rng = random.Random(20261014)
        if algorithm == "range_bitwise_and":
            pairs.update((left, right) for left, right in ((I32_MAX + 1, I32_MAX + 1),
                                                            (0, U64_MAX), (I32_MAX, 0)))
        elif algorithm == "addition_without_arithmetic":
            pairs.update((rng.randrange(I32_MIN - 1, I32_MAX + 2),
                          rng.randrange(I32_MIN - 1, I32_MAX + 2)) for _ in range(512))
        elif algorithm == "amicable_number":
            pairs.update((rng.randrange(1, 1_000_000_001),
                          rng.randrange(1, 1_000_000_001)) for _ in range(128))
        elif algorithm == "first_bad_version":
            for _ in range(512):
                version_count = rng.randrange(1, I32_MAX + 1)
                if rng.randrange(4) == 0:
                    first_bad = rng.choice([0, version_count + 1])
                else:
                    first_bad = rng.randrange(1, version_count + 1)
                pairs.add((version_count, first_bad))
        else:
            pairs.update((rng.getrandbits(random_bits), rng.getrandbits(random_bits)) for _ in range(512))
    for case in workload["cases"]:
        left, right, expected = encode_values(case)
        if expected != result(algorithm, left, right):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
    data = "".join(
        f"{left if left >= 0 else left + (1 << 64)} "
        f"{right if right >= 0 else right + (1 << 64)} "
        f"{result(algorithm, left, right)}\n"
        for left, right in sorted(pairs)
    )
    return data, len(pairs)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="binary_scalar")
    checker = manifest["binaries"]["binary_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=90)
    if checked.returncode:
        raise RuntimeError(f"binary C ABI correctness check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_binary_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=90)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        left, right, expected = encode_values(case)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [left, right]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/binary_scalar")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages) or len(set(args.algorithms)) != len(args.algorithms):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {}
    corpora = {}
    corpus_paths = {}
    for algorithm in args.algorithms:
        workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
        workloads[algorithm] = json.loads(workload_path.read_text(encoding="utf-8"))
        corpora[algorithm] = corpus(algorithm, workloads[algorithm])
        corpus_paths[algorithm] = directory / f"{algorithm}-corpus.txt"
        corpus_paths[algorithm].write_text(corpora[algorithm][0], encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            data, case_count = corpora[algorithm]
            workload = workloads[algorithm]
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      directory / algorithm[0] / algorithm / language,
                                      args.elisa_compiler, data, case_count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
                print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle pairs, "
                      f"{result['workload_records']} workload records", flush=True)
            except Exception as error:
                result = {"algorithm": algorithm, "language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "algorithms": args.algorithms, "languages": args.languages,
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": all(result["status"] == "passed" for result in results),
              "corpora": {algorithm: {"path": str(corpus_paths[algorithm]),
                                      "sha256": hashlib.sha256(corpora[algorithm][0].encode()).hexdigest()}
                          for algorithm in args.algorithms},
              "verification_source_sha256": sha256_file(Path(__file__)),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_binary_scalar.py"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "workloads": {algorithm: sha256_file(ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                            for algorithm in args.algorithms},
              "results": sorted(results, key=lambda result: (result["algorithm"], result["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
