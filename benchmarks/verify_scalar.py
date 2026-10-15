#!/usr/bin/env python3
"""Build and check the reviewed scalar algorithms against independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import json
import math
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_scalar import EXTENSIONS, ROOT, build, sha256_file

ALGORITHMS = ("factorial", "fibonacci", "tribonacci", "bitwise_complement", "aliquot_sum", "abundant_number", "armstrong_number", "lcm_sum", "leonardo_number", "signum", "is_even", "double_factorial", "power_of_two", "prime_check", "perfect_number", "catalan_number", "number_of_digits", "digital_root", "happy_number", "automorphic_number", "palindrome_number", "power_of_four", "fibonacci_fast", "lucas_series", "lucas_series_recursive", "hamming_weight", "reverse_bits")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def fibonacci_pair(n: int) -> tuple[int, int]:
    """Fast doubling oracle; independent of the ports' linear recurrence."""
    if n == 0:
        return 0, 1
    a, b = fibonacci_pair(n // 2)
    even, odd = a * (2 * b - a), a * a + b * b
    return (odd, even + odd) if n % 2 else (even, odd)


def oracle(algorithm: str, n: int) -> int:
    if algorithm == "digital_root":
        if n < 0:
            return -1
        while n >= 10:
            total = 0
            while n > 0:
                total += n % 10
                n //= 10
            n = total
        return n
    if algorithm == "hamming_weight":
        if not 0 <= n <= 2**32 - 1:
            return -1
        return sum((n >> bit) & 1 for bit in range(32))
    if algorithm == "reverse_bits":
        if not 0 <= n <= 2**32 - 1:
            return -1
        return int(f"{n:032b}"[::-1], 2)
    if algorithm in {"lucas_series", "lucas_series_recursive"}:
        maximum = 90 if algorithm == "lucas_series" else 25
        if not 0 <= n <= maximum:
            return -1
        previous, current = 2, 1
        for _ in range(n):
            previous, current = current, previous + current
        return previous
    if algorithm == "power_of_four":
        if not -(2**31) <= n <= 2**31 - 1:
            return -1
        return int(n > 0 and (n & (n - 1)) == 0 and (n & 0x55555555) != 0)
    if algorithm == "bitwise_complement":
        if not 0 <= n <= 2**31 - 1:
            return -1
        return 1 if n == 0 else n ^ ((1 << n.bit_length()) - 1)
    if algorithm == "palindrome_number":
        if not 0 <= n <= 2**31 - 1:
            return -1
        digits = str(n)
        return int(digits == digits[::-1])
    if algorithm == "number_of_digits":
        return len(str(abs(n)))
    if algorithm == "happy_number":
        if n <= 0:
            return -1
        seen = set()
        while n != 1 and n not in seen:
            seen.add(n)
            total = 0
            while n:
                digit = n % 10
                total += digit * digit
                n //= 10
            n = total
        return int(n == 1)
    if algorithm == "automorphic_number":
        if n < 0:
            return 0
        modulus = 10 ** len(str(n))
        return int((n * n) % modulus == n)
    if algorithm == "lcm_sum":
        if not 1 <= n <= 65535:
            return -1
        return sum((index // math.gcd(index, n)) * n for index in range(1, n + 1))
    if algorithm == "leonardo_number":
        return 2 * fibonacci_pair(n + 1)[0] - 1 if 0 <= n <= 89 else -1
    if algorithm == "signum":
        return (n > 0) - (n < 0)
    if algorithm == "is_even":
        return int(n % 2 == 0)
    if algorithm == "double_factorial":
        if n < 0 or n > 33:
            return -1
        result = 1
        factor = n
        while factor > 1:
            result *= factor
            factor -= 2
        return result
    if algorithm == "power_of_two":
        return int(n > 0 and (n & (n - 1)) == 0)
    if algorithm == "prime_check":
        if n < 2:
            return 0
        if n > 2**31 - 1:
            return -1
        for factor in range(2, math.isqrt(n) + 1):
            if n % factor == 0:
                return 0
        return 1
    if algorithm == "perfect_number":
        if n < 2:
            return 0
        if n > 1_000_000_000_000:
            return -1
        # Compute sigma(n) from its prime factorization, independently of the
        # divisor-pair scan used by the implementations.
        remaining, sigma, factor = n, 1, 2
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
        return int(sigma - n == n)
    if algorithm == "number_of_digits":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -10**18, -10**17, -10, -1, 0, 1,
                       9, 10, 10**17, 10**18, I64_MAX - 1, I64_MAX])
        for power in range(1, 19):
            value = 10 ** power
            inputs.update([value - 1, value, value + 1, -value + 1, -value, -value - 1])
    if algorithm == "catalan_number":
        return math.comb(2 * n, n) // (n + 1) if 0 <= n <= 35 else -1
    if algorithm == "factorial":
        return math.factorial(n) if 0 <= n <= 20 else -1
    if algorithm in {"fibonacci", "fibonacci_fast"}:
        return fibonacci_pair(n)[0] if 0 <= n <= 92 else -1
    if algorithm == "tribonacci":
        if not 0 <= n <= 73:
            return -1
        if n == 0:
            return 0
        previous_three, previous_two, previous_one = 0, 1, 1
        for _ in range(3, n + 1):
            previous_three, previous_two, previous_one = (
                previous_two, previous_one, previous_three + previous_two + previous_one)
        return (previous_three, previous_two, previous_one)[n] if n < 3 else previous_one
    if algorithm == "armstrong_number":
        if n < 0:
            return 0
        digits = str(n)
        return int(sum(int(digit) ** len(digits) for digit in digits) == n)
    if algorithm == "aliquot_sum":
        if n < 0:
            return -1
        if n == 0:
            return 0
        # Multiplicative sigma formula from prime factorization, rather than a divisor scan.
        remaining, sigma, prime = n, 1, 2
        while prime * prime <= remaining:
            prime_power, term = 1, 1
            while remaining % prime == 0:
                remaining //= prime
                prime_power *= prime
                term += prime_power
            sigma *= term
            prime += 1
        if remaining > 1:
            sigma *= remaining + 1
        result = sigma - n
        return result if result <= I64_MAX else -1
    if algorithm == "abundant_number":
        if not 1 <= n <= 1_000_000_000:
            return -1
        # Multiplicative sigma oracle; ports instead scan factor pairs.
        remaining, sigma, factor = n, 1, 2
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
        return int(sigma > 2 * n)
    raise ValueError(f"no independent oracle for {algorithm}")


def corpus(algorithm: str) -> tuple[str, dict]:
    workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    rng = random.Random(20261014)
    inputs = {case["input_value"] for case in workload["cases"]}
    if algorithm == "lucas_series":
        inputs.update(range(-4, 96))
        inputs.update([I64_MIN, I64_MIN + 1, 89, 90, 91, I64_MAX - 1, I64_MAX])
    elif algorithm == "lucas_series_recursive":
        inputs.update(range(-4, 27))
        inputs.update([I64_MIN, I64_MIN + 1, 24, 25, 26, I64_MAX - 1, I64_MAX])
    elif algorithm == "factorial":
        inputs.update(range(-4, 26))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm in {"fibonacci", "fibonacci_fast"}:
        inputs.update(range(-4, 98))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "tribonacci":
        inputs.update(range(-4, 79))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "hamming_weight":
        inputs.update(range(-4, 65536))
        inputs.update(rng.randrange(0, 2**32) for _ in range(512))
        inputs.update([-1, 0, 1, 2, 3, 0x55555555, 0xAAAAAAAA,
                       1 << 31, 2**32 - 1, 2**32, I64_MAX])
        for bit in range(32):
            value = 1 << bit
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "reverse_bits":
        inputs.update(range(-4, 65536))
        inputs.update(rng.randrange(0, 2**32) for _ in range(512))
        inputs.update([I64_MIN, -1, 0, 1, 2, 3, 0x55555555, 0xAAAAAAAA,
                       1 << 31, 2**32 - 1, 2**32, I64_MAX])
        for bit in range(32):
            value = 1 << bit
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "bitwise_complement":
        inputs.update(range(-8, 4097))
        inputs.update(rng.randrange(0, 2**31) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, 5,
                       2**30 - 1, 2**30, 2**30 + 1, 2**31 - 2,
                       2**31 - 1, 2**31, I64_MAX - 1, I64_MAX])
    elif algorithm == "aliquot_sum":
        inputs.update(range(513))
        inputs.update(rng.randrange(1, 10001) for _ in range(128))
        # Positive extremes are intentionally not sent through an O(n) implementation.
        inputs.update([I64_MIN, -1000, -2])
    elif algorithm == "abundant_number":
        inputs.update(range(-16, 10000))
        inputs.update(rng.randrange(1, 10_000_001) for _ in range(128))
        inputs.update([I64_MIN, -1, 0, 1, 2, 6, 12, 20, 28, 945,
                       999_999_936, 999_999_937, 1_000_000_000,
                       1_000_000_001, I64_MAX])
    elif algorithm == "armstrong_number":
        inputs.update(range(10000))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(256))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
        for case in workload["cases"]:
            n = case["input_value"]
            if n > 10000:
                inputs.update(value for value in (n - 1, n + 1) if value <= I64_MAX)
    elif algorithm == "lcm_sum":
        inputs.update(range(-8, 513))
        inputs.update(rng.randrange(1, 10001) for _ in range(192))
        inputs.update([I64_MIN, -2, -1, 65534, 65535, 65536, I64_MAX])
    elif algorithm == "leonardo_number":
        inputs.update(range(-4, 100))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "signum":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "is_even":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "double_factorial":
        inputs.update(range(-4, 41))
        inputs.update([I64_MIN, I64_MIN + 1, I64_MAX - 1, I64_MAX])
    elif algorithm == "power_of_two":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, I64_MAX - 1, I64_MAX])
        inputs.update(1 << bit for bit in range(63))
        inputs.update((1 << bit) - 1 for bit in range(1, 63))
        inputs.update((1 << bit) + 1 for bit in range(1, 63) if (1 << bit) < I64_MAX)
    elif algorithm == "prime_check":
        inputs.update(range(-1024, 10001))
        inputs.update(rng.randrange(0, 2**31) for _ in range(128))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 3, 4, 5, 9, 25, 49,
                       115248, 115249, 2147483646, 2147483647, 2147483648, I64_MAX])
    elif algorithm == "perfect_number":
        inputs.update(range(-32, 10001))
        inputs.update(rng.randrange(2, 100_000_001) for _ in range(64))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 5, 6, 7, 27, 28, 29,
                       495, 496, 497, 8127, 8128, 8129, 33550335,
                       33550336, 33550337, 1_000_000_000_000,
                       1_000_000_000_001, I64_MAX])
    elif algorithm == "number_of_digits":
        inputs.update(range(-1024, 1025))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -10**18, -10**17, -10, -1, 0, 1, 9, 10, 10**17, 10**18, I64_MAX - 1, I64_MAX])
        for power in range(1, 19):
            value = 10 ** power
            inputs.update([value - 1, value, value + 1, -value + 1, -value, -value - 1])
    elif algorithm == "digital_root":
        inputs.update(range(-16, 10_001))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 9, 10, 19, 38, 284,
                       999, 1000, 9999, 10**18 - 1, 10**18, 10**18 + 1,
                       I64_MAX - 1, I64_MAX])
    elif algorithm == "happy_number":
        inputs.update(range(-32, 10001))
        inputs.update(rng.randrange(1, I64_MAX + 1) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 2, 3, 4, 7, 10, 19,
                       20, 23, 28, 31, 68, 70, 82, 86, 89, 97, 100, 101,
                       1000, 10**18, I64_MAX - 1, I64_MAX])
    elif algorithm == "automorphic_number":
        inputs.update(range(-32, 100001))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(512))
        known = [0, 1, 5, 6, 25, 76, 376, 625, 9376, 90625,
                 259918212890625, 740081787109376]
        for value in known:
            inputs.update([value - 1, value, value + 1])
        inputs.update([I64_MIN, I64_MIN + 1, -1, I64_MAX - 1, I64_MAX])
    elif algorithm == "palindrome_number":
        inputs.update(range(-16, 100_001))
        inputs.update(rng.randrange(-1, 2**31 + 2) for _ in range(512))
        inputs.update([I64_MIN, I64_MIN + 1, -1, 0, 1, 9, 10, 11, 99, 100,
                       101, 1001, 1000000001, 2147447412, 2**31 - 1,
                       2**31, I64_MAX - 1, I64_MAX])
    elif algorithm == "power_of_four":
        inputs.update(range(-1024, 10_001))
        inputs.update(rng.randrange(-(2**31) - 1, 2**31 + 2) for _ in range(512))
        inputs.update([I64_MIN, -(2**31) - 1, -(2**31), -1, 0, 1, 2, 3, 4, 8,
                       16, 32, 64, 128, 256, 1024, 1 << 29, 1 << 30,
                       2**31 - 1, 2**31, I64_MAX])
        for exponent in range(16):
            value = 4**exponent
            inputs.update([value - 1, value, value + 1])
    elif algorithm == "catalan_number":
        inputs.update(range(-4, 42))
        inputs.update(rng.randrange(I64_MIN, I64_MAX + 1) for _ in range(256))
        inputs.update([I64_MIN, -2, -1, 0, 1, 2, 3, 4, 5, 20, 25, 30,
                       34, 35, 36, 50, I64_MAX])
    for case in workload["cases"]:
        expected = oracle(algorithm, case["input_value"])
        if case["expected_result"] != expected:
            raise ValueError(f"workload oracle mismatch: {algorithm}/{case['id']}")
    data = "".join(f"{n} {oracle(algorithm, n)}\n" for n in sorted(inputs))
    return data, workload


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, workload: dict) -> dict:
    compiler = elisa_compiler if language == "elisa" else None
    manifest = build(algorithm, language, directory, compiler=compiler, with_checker=True)
    checker = manifest["binaries"]["scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=60)
    if checked.returncode:
        raise RuntimeError(f"C ABI correctness check failed: {checked.stderr}")
    count = json.loads(checked.stdout)["cases_checked"]
    if count != len(data.splitlines()):
        raise RuntimeError("checker did not consume the entire oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    command = [sys.executable, str(ROOT / "benchmarks/run_scalar.py"),
               "--algorithm", algorithm, "--language", language,
               "--source", str(ROOT / manifest["source_path"]),
               "--executable", manifest["binaries"]["scalar_runner"]["path"],
               "--compiler", manifest["compiler"], "--compiler-version", manifest["compiler_version"],
               "--build-flags=" + manifest["build_flags"],
               "--build-command", "\n".join(shlex.join(c) for c in manifest["commands"]),
               "--samples", "1", "--warmups", "0", "--repetitions", "1",
               "--output", str(records_path)]
    recorded = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=60)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != algorithm or record["implementation"]["language"] != language
                or record["workload"]["input_value"] != case["input_value"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["workload"]["input_length"] is not None
                or len(record["measurement"]["samples_ns"]) != 1
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]):
            raise RuntimeError(f"recorder result/provenance mismatch in {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "source_sha256": manifest["source_sha256"], "oracle_cases": count,
            "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
            "workload_cases": len(records), "workload_sha256": sha256_file(
                ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/scalar")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if args.jobs < 1:
        parser.error("--jobs must be positive")
    if len(set(args.algorithms)) != len(args.algorithms) or len(set(args.languages)) != len(args.languages):
        parser.error("algorithm and language selections must not contain duplicates")
    directory = args.build_dir.resolve()
    corpora = {algorithm: corpus(algorithm) for algorithm in args.algorithms}
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            for language in args.languages:
                output = directory / algorithm[0] / algorithm / language
                data, workload = corpora[algorithm]
                job = executor.submit(verify, algorithm, language, output,
                                      args.elisa_compiler, data, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
                print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle cases, "
                      f"{result['workload_cases']} workload records", flush=True)
            except Exception as error:
                result = {"algorithm": algorithm, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report_path = (args.report or directory / "verification.json").resolve()
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "algorithms": args.algorithms, "languages": args.languages,
              "verification_source_sha256": sha256_file(Path(__file__)),
              "build_source_sha256": sha256_file(ROOT / "benchmarks/build_scalar.py"),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_scalar.py"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "all_passed": all(result["status"] == "passed" for result in results),
              "results": sorted(results, key=lambda r: (r["algorithm"], r["language"]))}
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
