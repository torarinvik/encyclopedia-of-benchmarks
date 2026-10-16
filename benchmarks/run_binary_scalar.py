#!/usr/bin/env python3
"""Record a built two-input scalar benchmark using its build manifest."""

from __future__ import annotations

import argparse
import datetime as dt
from functools import lru_cache
import json
import math
import os
from pathlib import Path
import platform
import shlex
import subprocess

from build_abi import ROOT, sha256_file
from modular_inverse_fermat_little_theorem_oracle import expected_result as modular_inverse_fermat_expected
from modular_inverse_simple_oracle import expected_result as modular_inverse_simple_expected
from fermat_prime_checker_oracle import expected_result as fermat_prime_checker_expected
from exponentiation_oracle import expected_result as exponentiation_expected
from uint53_xor_oracle import expected_result as uint53_xor_expected

U64_MAX = 2**64 - 1
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
DIGIT_FACTORIALS = (1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880)


@lru_cache(maxsize=8)
def problem800_source_result(base: int, degree: int) -> int:
    """Mirror the pinned sieve and decreasing-right-pointer traversal."""
    if not 2 <= base <= 1_000_000 or not 1 <= degree <= 1_000_000:
        return -1
    upper_bound = degree * math.log2(base)
    max_prime = int(upper_bound)
    if max_prime <= 2:
        return 0
    is_prime = bytearray(b"\x01") * max_prime
    is_prime[0:2] = b"\x00\x00"
    for prime in range(2, math.isqrt(max_prime - 1) + 1):
        if is_prime[prime]:
            start = prime * prime
            is_prime[start:max_prime:prime] = b"\\x00" * (((max_prime - 1 - start) // prime) + 1)
    primes = [value for value in range(2, max_prime) if is_prime[value]]
    count = 0
    left, right = 0, len(primes) - 1
    while left < right:
        while (primes[right] * math.log2(primes[left])
               + primes[left] * math.log2(primes[right]) > upper_bound):
            right -= 1
        count += right - left
        left += 1
    return count


def problem74_count(num_terms: int, max_start: int) -> int:
    if max_start > 1_000_000:
        return -1
    if max_start <= 1:
        return 0
    cache = {145: 0, 169: 3, 36301: 3, 1454: 3, 871: 2, 45361: 2, 872: 2}

    def digit_factorial_sum(value: int) -> int:
        total = 0
        while True:
            total += DIGIT_FACTORIALS[value % 10]
            value //= 10
            if value == 0:
                return total

    def chain_length(start: int) -> int:
        path: list[int] = []
        path_members: set[int] = set()
        current = start
        while current not in cache:
            next_value = digit_factorial_sum(current)
            if next_value in path_members:
                cache[current] = 0
                result = 0
                break
            path.append(current)
            path_members.add(current)
            current = next_value
        else:
            result = cache[current]
        while path:
            current = path.pop()
            result += 1
            cache[current] = result
        return cache[start]

    return sum(chain_length(start) == num_terms for start in range(1, max_start))


def problem174_source_result(t_limit: int, n_limit: int) -> int:
    """Mirror the pinned outer-width and parity-adjusted hole-width scan."""
    if (not I64_MIN <= t_limit <= I64_MAX
            or not I64_MIN <= n_limit <= I64_MAX
            or t_limit > 1_000_000):
        return -1
    if t_limit < 0:
        return 0
    counts = bytearray(t_limit + 1)
    for outer_width in range(3, t_limit // 4 + 2):
        outer_area = outer_width * outer_width
        hole_lower = (max(math.ceil(math.sqrt(outer_area - t_limit)), 1)
                      if outer_area > t_limit else 1)
        hole_lower += (outer_width - hole_lower) % 2
        for hole_width in range(hole_lower, outer_width - 1, 2):
            counts[outer_area - hole_width * hole_width] += 1
    return sum(1 <= count <= n_limit for count in counts)


def trinomial_triangle_source_result(n: int, k: int) -> int:
    """Mirror the pinned three-parent recurrence for bounded (n, k)."""
    if k < -n or k > n:
        return 0
    if n == 0:
        return 1
    return (trinomial_triangle_source_result(n - 1, k - 1)
            + trinomial_triangle_source_result(n - 1, k)
            + trinomial_triangle_source_result(n - 1, k + 1))


def encode_values(case: dict, algorithm: str) -> tuple[int, int, int]:
    values = case.get("input_values")
    expected = case.get("expected_result")
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= U64_MAX for value in values)
            or type(expected) is not int):
        raise ValueError("binary scalar cases require two 64-bit inputs and an integer result")
    if algorithm == "binary_multiplication":
        left, right = values
        if not (0 <= left <= 1_000_000_000 and 0 <= right <= 1_000_000_000):
            raise ValueError("binary_multiplication workload inputs must lie within the declared 0..1e9 domain")
        if expected != left * right:
            raise ValueError("binary_multiplication expected_result must equal the bounded product")
    elif algorithm == "imply_gate":
        left, right = values
        valid = left in (0, 1) and right in (0, 1)
        expected_from_source = int(left == 0 or right == 1) if valid else -1
        if expected != expected_from_source:
            raise ValueError("imply_gate expected_result must match Boolean implication over 0/1 inputs")
    elif algorithm == "uint53_xor":
        expected_from_source = uint53_xor_expected(values[0], values[1])
        if expected != expected_from_source:
            raise ValueError("uint53_xor expected_result must match bounded numeric XOR")
    elif algorithm == "unique_paths":
        rows, columns = values
        if not (0 <= rows <= U64_MAX and 0 <= columns <= U64_MAX):
            expected_from_source = -1
        elif not (1 <= rows <= 34 and 1 <= columns <= 34):
            expected_from_source = -1
        else:
            expected_from_source = math.comb(rows + columns - 2, rows - 1)
        if expected != expected_from_source:
            raise ValueError("unique_paths expected_result must match the bounded binomial count")
    elif algorithm == "circular_left_shift":
        number, shift = values
        valid = 0 <= number <= (1 << 53) - 1 and 0 <= shift <= 53
        if not valid:
            expected_from_source = -1
        else:
            rotation = shift % 53
            mask = (1 << 53) - 1
            expected_from_source = ((number << rotation) | (number >> (53 - rotation))) & mask
        if expected != expected_from_source:
            raise ValueError("circular_left_shift expected_result must match a bounded 53-bit rotation")
    elif algorithm in {"arithmetic_left_shift", "arithmetic_right_shift"}:
        number, shift = values
        valid = 0 <= number <= (1 << 53) - 1 and 0 <= shift <= 53
        if not valid:
            expected_from_source = -1
        elif algorithm == "arithmetic_left_shift":
            expected_from_source = (number * (1 << shift)) % (1 << 53)
        else:
            most_significant_bit = number // (1 << 52)
            fill = (1 << 53) - (1 << (53 - shift))
            expected_from_source = most_significant_bit * fill + number // (1 << shift)
        if expected != expected_from_source:
            raise ValueError(f"{algorithm} expected_result disagrees with its bounded uint53 shift")
    elif algorithm == "problem800":
        base, degree = values
        expected_from_source = problem800_source_result(base, degree)
        if expected != expected_from_source:
            raise ValueError("problem800 expected_result must match the pinned binary64 prime-pointer traversal")
    elif algorithm == "problem56":
        a, b = values
        valid = 1 <= a <= 200 and 1 <= b <= 200
        expected_from_source = (-1 if not valid else
            max(sum(int(digit) for digit in str(pow(base, power)))
                for base in range(a) for power in range(b)))
        if expected != expected_from_source:
            raise ValueError("problem56 expected_result must match the bounded arbitrary-precision digit-sum search")
    elif algorithm == "problem74":
        num_terms, max_start = values
        if not all(I64_MIN <= value <= I64_MAX for value in values):
            expected_from_source = -1
        else:
            expected_from_source = problem74_count(num_terms, max_start)
        if expected != expected_from_source:
            raise ValueError("problem74 expected_result must match the seeded digit-factorial chain scan")
    elif algorithm == "problem174":
        t_limit, n_limit = values
        expected_from_source = problem174_source_result(t_limit, n_limit)
        if expected != expected_from_source:
            raise ValueError("problem174 expected_result must match the pinned bounded lamina-count scan")
    elif algorithm == "problem124":
        n_max, rank = values
        if 1 <= rank <= n_max <= 100_000:
            radicals = [1] * (n_max + 1)
            for prime in range(2, n_max + 1):
                if radicals[prime] == 1:
                    for multiple in range(prime, n_max + 1, prime):
                        radicals[multiple] *= prime
            ordered = sorted(range(1, n_max + 1), key=lambda value: (radicals[value], value))
            expected_from_source = ordered[rank - 1]
        else:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("problem124 expected_result must match radical ordering with ascending ties")
    elif algorithm == "problem63":
        max_base, max_power = values
        valid = all(I64_MIN <= value <= 2**63 - 1 for value in values)
        expected_from_source = -1
        if valid:
            expected_from_source = sum(
                len(str(base ** power)) == power
                for base in range(1, min(max_base, 10))
                for power in range(1, min(max_power, 22)))
        if expected != expected_from_source:
            raise ValueError("problem63 expected_result must count exact digit-power matches in the exclusive bounds")
    elif algorithm == "count_number_of_one_bits":
        number, method = values
        valid = 0 <= number <= 0xFFFFFFFF and 0 <= method <= 2
        expected_from_source = bin(number).count("1") if valid else -1
        if expected != expected_from_source:
            raise ValueError("count_number_of_one_bits expected_result does not match its selected source variant")
    elif algorithm == "bitwise_addition_recursive":
        first, second = values
        valid = 0 <= first <= 2**31 - 1 and 0 <= second <= 2**31 - 1
        expected_from_source = first + second if valid else -1
        if expected != expected_from_source:
            raise ValueError("bitwise_addition_recursive expected_result must equal the bounded nonnegative sum")
    elif algorithm == "first_different_bit":
        first, second = values
        valid = (-(2**31) <= first <= 2**31 - 1
                 and -(2**31) <= second <= 2**31 - 1)
        if not valid:
            expected_from_source = -1
        else:
            difference = (first & 0xFFFFFFFF) ^ (second & 0xFFFFFFFF)
            expected_from_source = 32 if difference == 0 else (difference & -difference).bit_length() - 1
        if expected != expected_from_source:
            raise ValueError("first_different_bit expected_result must be the trailing-zero count of the 32-bit XOR")
    elif algorithm == "recursive_digit_sum":
        number, repetitions = values
        valid = 0 <= number <= 2**63 - 1 and 0 <= repetitions <= 1_000_000
        if valid:
            total = sum(int(digit) for digit in str(number)) * repetitions
            while total >= 10:
                total = sum(int(digit) for digit in str(total))
            expected_from_source = total
        else:
            expected_from_source = -1
        if expected != expected_from_source:
            raise ValueError("recursive_digit_sum expected_result does not match the pinned super-digit definition")
    elif algorithm == "xor_swap_two_integers":
        first, second = values
        valid = -32768 <= first <= 32767 and -32768 <= second <= 32767
        expected_from_source = (second + 32768) * 65536 + (first + 32768) if valid else -1
        if expected != expected_from_source:
            raise ValueError("xor_swap_two_integers expected_result must encode the swapped pair")
    elif algorithm == "highest_common_factor":
        left, right = values
        valid = 0 <= left <= 64 and 0 <= right <= 64
        if not valid:
            raise ValueError("highest_common_factor workload inputs must lie within the declared 0..64 domain")
        if expected != math.gcd(left, right):
            raise ValueError("highest_common_factor expected_result must match bounded subtractive GCD")
    elif algorithm in {"max_value", "min_value"}:
        first, second = values
        valid = (-(2**31) <= first <= 2**31 - 1
                 and -(2**31) <= second <= 2**31 - 1)
        if not valid:
            expected_from_source = -1
        else:
            expected_from_source = (max(first, second) if algorithm == "max_value"
                                    else min(first, second))
        if expected != expected_from_source:
            raise ValueError(f"{algorithm} expected_result must match the signed-i32 comparison")
    elif algorithm == "sum_without_arithmetic_operators":
        first, second = values
        valid = (-(2**31) <= first <= 2**31 - 1
                 and -(2**31) <= second <= 2**31 - 1)
        if valid:
            wrapped = (first + second) & 0xFFFFFFFF
            expected_from_source = wrapped - 0x100000000 if wrapped >= 0x80000000 else wrapped
        else:
            expected_from_source = -2_147_483_649
        if expected != expected_from_source:
            raise ValueError("sum_without_arithmetic_operators expected_result must match Java i32 wraparound")
    elif algorithm == "binary_pow":
        base, exponent = values
        valid = (-(2**31) <= base <= 2**31 - 1
                 and -(2**31) <= exponent <= 2**31 - 1)
        if not valid:
            expected_from_source = -2_147_483_649
        elif exponent <= 0:
            expected_from_source = 1
        else:
            result, wrapped_base, remaining = 1, base & 0xFFFFFFFF, exponent
            while remaining:
                if remaining & 1:
                    result = (result * wrapped_base) & 0xFFFFFFFF
                wrapped_base = (wrapped_base * wrapped_base) & 0xFFFFFFFF
                remaining >>= 1
            expected_from_source = result - 0x100000000 if result >= 0x80000000 else result
        if expected != expected_from_source:
            raise ValueError("binary_pow expected_result must match Java int exponentiation by squaring")
    elif algorithm == "modular_inverse":
        value, modulus = values
        valid = 0 <= value <= 1_000_000 and 2 <= modulus <= 1_000_000
        if not valid or math.gcd(value, modulus) != 1:
            expected_from_source = -1
        else:
            expected_from_source = pow(value, -1, modulus)
        if expected != expected_from_source:
            raise ValueError("modular_inverse expected_result must match the bounded least-positive modular inverse")
    elif algorithm == "modular_inverse_fermat_little_theorem":
        expected_from_source = modular_inverse_fermat_expected(values)
        if expected != expected_from_source:
            raise ValueError("modular_inverse_fermat_little_theorem expected_result must match bounded Fermat inversion")
    elif algorithm == "modular_inverse_simple":
        expected_from_source = modular_inverse_simple_expected(values)
        if expected != expected_from_source:
            raise ValueError("modular_inverse_simple expected_result must match bounded iterative inversion")
    elif algorithm == "fermat_prime_checker":
        expected_from_source = fermat_prime_checker_expected(values)
        if expected != expected_from_source:
            raise ValueError("fermat_prime_checker expected_result must match seeded bounded Fermat checking")
    elif algorithm == "exponentiation":
        expected_from_source = exponentiation_expected(values)
        if expected != expected_from_source:
            raise ValueError("exponentiation expected_result must match bounded unmodded integer power")
    elif algorithm == "trinomial_triangle":
        n, k = values
        if not 0 <= n <= 10 or not -10 <= k <= 10:
            expected_from_source = -1
        else:
            expected_from_source = trinomial_triangle_source_result(n, k)
        if expected != expected_from_source:
            raise ValueError("trinomial_triangle expected_result must match the bounded three-parent recurrence")
    return values[0], values[1], expected


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", required=True, type=Path)
    parser.add_argument("--workload", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--samples", type=int)
    parser.add_argument("--warmups", type=int)
    parser.add_argument("--repetitions", type=int)
    args = parser.parse_args()
    manifest = json.loads(args.build_manifest.read_text(encoding="utf-8"))
    if manifest.get("family") != "binary_scalar":
        parser.error("build manifest must declare the binary_scalar ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["binary_scalar_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/binary_scalar_runner.c"
    if (sha256_file(source) != manifest["source_sha256"] or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")
    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "binary_scalar_call"):
        parser.error("workload does not match the built binary scalar algorithm")
    timing = workload["measurement"]
    samples = args.samples if args.samples is not None else timing["sample_count"]
    warmups = args.warmups if args.warmups is not None else timing["warmup_rounds"]
    repetitions = args.repetitions if args.repetitions is not None else timing["repetitions_per_sample"]
    if not 1 <= samples <= 10000 or not 0 <= warmups <= 100000 or not 1 <= repetitions <= 1000000000:
        parser.error("sample/warmup/repetition counts exceed the runner limits")
    if len({case["id"] for case in workload["cases"]}) != len(workload["cases"]):
        parser.error("workload case IDs must be unique")
    run_id = dt.datetime.now(dt.timezone.utc).isoformat(timespec="microseconds").replace("+00:00", "Z")
    implementation = {key: manifest[key] for key in (
        "language", "source_path", "source_sha256", "compiler", "compiler_version", "build_flags")}
    implementation.update({"runner_source_sha256": binary["harness_sha256"],
                           "binary_sha256": binary["sha256"],
                           "build_command": "\n".join(shlex.join(command) for command in manifest["commands"])})
    environment = {"os": platform.system(), "os_release": platform.release(),
                   "architecture": platform.machine(), "cpu_model": platform.processor().strip() or None,
                   "logical_cpu_count": os.cpu_count(), "python_version": platform.python_version()}
    records = []
    for case in workload["cases"]:
        left, right, expected = encode_values(case, algorithm)
        abi_left = left if left >= 0 else left + (1 << 64)
        abi_right = right if right >= 0 else right + (1 << 64)
        command = [str(executable), str(abi_left), str(abi_right), str(expected),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"binary scalar runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        if raw["observed_result"] != expected or len(raw["samples_ns"]) != samples:
            raise ValueError(f"binary scalar runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_values": [left, right],
                                     "case": case["id"], "target": None, "expected_result": expected},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "binary_scalar_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups,
                                        "repetitions_per_sample": repetitions,
                                        "samples_ns": raw["samples_ns"],
                                        "observed_result": raw["observed_result"],
                                        "result_checksum": raw["result_checksum"]}})
    output = args.output or ROOT / "results" / letter / algorithm / f"{language}.jsonl"
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("a", encoding="utf-8", newline="\n") as destination:
        for record in records:
            destination.write(json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n")
    print(f"appended {len(records)} result records to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
