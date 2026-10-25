#!/usr/bin/env python3
"""Record a scalar-to-byte-output benchmark from its ABI build manifest."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import shlex
import struct
import subprocess

from build_abi import ROOT, sha256_file
from ary3_oracle import expected_output as ary3_expected_output
from prime_factorial_oracle import expected_output as prime_factorial_expected_output
from stream_sieve_oracle import expected_output as stream_sieve_expected_output
from shootout_random_oracle import expected_output as shootout_random_expected_output
from shootout_hello_oracle import expected_output as shootout_hello_expected_output
from shootout_lists_oracle import expected_output as shootout_lists_expected_output
from shootout_strcat_oracle import expected_output as shootout_strcat_expected_output
from shootout_methcall_oracle import expected_output as shootout_methcall_expected_output
from shootout_objinst_oracle import expected_output as shootout_objinst_expected_output
from benchmarkgame_recursive_oracle import expected_output as benchmarkgame_recursive_expected_output
from almabench_oracle import expected_output as almabench_expected_output
from queens_oracle import expected_output as queens_expected_output
from npb_is_oracle import expected_output as npb_is_expected_output
from stanford_queens_oracle import expected_output as stanford_queens_expected_output
from evalloop_oracle import expected_output as evalloop_expected_output
from mcgill_misr_oracle import expected_output as mcgill_misr_expected_output
from huffbench_oracle import MAX_PASSES as HUFFBENCH_MAX_PASSES
from huffbench_oracle import MIN_PASSES as HUFFBENCH_MIN_PASSES
from huffbench_oracle import expected_output as huffbench_expected_output

MAX_OUTPUT_BYTES = 8192


def expected_output(value: int, encoding: int | str = 2) -> tuple[int, bytes]:
    if encoding == "shootout_ary3_ascii":
        return ary3_expected_output(value)
    if encoding == "stream_sieve_primes_i32le":
        return stream_sieve_expected_output(value)
    if encoding == "shootout_random_ascii":
        return shootout_random_expected_output(value)
    if encoding == "shootout_hello_stdout_ascii":
        return shootout_hello_expected_output(value)
    if encoding == "shootout_lists_stdout_ascii":
        return shootout_lists_expected_output(value)
    if encoding == "shootout_strcat_stdout_ascii":
        return shootout_strcat_expected_output(value)
    if encoding == "shootout_methcall_stdout_ascii":
        return shootout_methcall_expected_output(value)
    if encoding == "shootout_objinst_stdout_ascii":
        return shootout_objinst_expected_output(value)
    if encoding == "benchmarkgame_recursive_ascii":
        return benchmarkgame_recursive_expected_output(value)
    if encoding == "almabench_ephemeris_ascii":
        return almabench_expected_output(value)
    if encoding == "mcgill_queens_count_ascii":
        return queens_expected_output(value)
    if encoding == "npb_is_class_w_ascii":
        return npb_is_expected_output(value)
    if encoding == "stanford_queens_runs":
        return stanford_queens_expected_output(value)
    if encoding == "evalloop_stdout_ascii":
        return evalloop_expected_output(value)
    if encoding == "mcgill_misr_report_ascii":
        return mcgill_misr_expected_output(value)
    if encoding == "huffbench_summary_ascii":
        if not HUFFBENCH_MIN_PASSES <= value <= HUFFBENCH_MAX_PASSES:
            return -1, b""
        output = huffbench_expected_output(value)
        if output is None:
            return -1, b""
        return len(output), output
    if encoding == "prime_factorial_unique_u32le":
        return prime_factorial_expected_output(value)
    if encoding == "magicdiamondpattern":
        if not -2**63 <= value <= 45:
            return -1, b""
        if value <= 0:
            output = b"       ...       ....        nothing printing :("
            return len(output), output
        side = value
        rows = []
        for count in range(1, side + 1):
            rows.append(" " * (side - count) + "* " * count + "\n")
        for count in range(side, 0, -1):
            rows.append("* " * count + "\n" + " " * (side - count + 1))
        output = "".join(rows).encode("ascii")
        return len(output), output
    if encoding == "butterfly_pattern":
        if not 1 <= value <= 45:
            return -1, b""
        rows = ["*" * count + " " * (2 * (value - count) - 1) + "*" * count
                for count in range(1, value)]
        rows.append("*" * (2 * value - 1))
        rows.extend("*" * count + " " * (2 * (value - count) - 1) + "*" * count
                    for count in range(value - 1, 0, -1))
        output = "\n".join(rows).encode("ascii")
        return len(output), output

    if encoding == "harmonic_series":
        if not -512 <= value <= 512:
            return -1, b""
        if value <= 0:
            return 0, b""
        output = "".join(f"1/{denominator}\n" if denominator > 1 else "1\n"
                         for denominator in range(1, value + 1)).encode("ascii")
        return len(output), output

    if encoding == "excess_3_code":
        number = max(0, value)
        digits = str(number)
        output = bytearray(b"0b")
        for digit in digits:
            nibble = int(digit) + 3
            output.extend(ord("1") if nibble & bit else ord("0")
                          for bit in (8, 4, 2, 1))
        result = bytes(output)
        return len(result), result

    if encoding == "floyd_triangle":
        if not 0 <= value <= 90:
            return -1, b""
        count = value * (value + 1) // 2
        output = b"".join(struct.pack("<H", number) for number in range(1, count + 1))
        return len(output), output

    if encoding == "comma_separated_decimal":
        if not 1 <= value <= 80:
            return -1, b""
        totients = []
        for number in range(1, value + 1):
            remainder = number
            result = number
            divisor = 2
            while divisor <= remainder // divisor:
                if remainder % divisor == 0:
                    result -= result // divisor
                    while remainder % divisor == 0:
                        remainder //= divisor
                divisor += 1
            if remainder > 1:
                result -= result // remainder
            totients.append(str(result))
        output = ",".join(totients).encode("ascii")
        return len(output), output

    if encoding == "decimal_to_gray":
        if not 0 <= value <= 2**63 - 1:
            return -1, b""
        output = format(value ^ (value >> 1), "b").encode("ascii")
        return len(output), output

    if encoding == "n_queens_backtracking_csharp":
        if not 0 <= value <= 8:
            return -1, b""
        if value == 0:
            return 8, struct.pack("<q", 0)
        solutions: list[tuple[int, ...]] = []
        placement = [-1] * value
        used_rows: set[int] = set()
        used_rising_diagonals: set[int] = set()
        used_falling_diagonals: set[int] = set()

        def search(column: int) -> None:
            if column == value:
                solutions.append(tuple(placement))
                return
            for row in range(value):
                rising = row - column
                falling = row + column
                if (row in used_rows or rising in used_rising_diagonals
                        or falling in used_falling_diagonals):
                    continue
                placement[column] = row
                used_rows.add(row)
                used_rising_diagonals.add(rising)
                used_falling_diagonals.add(falling)
                search(column + 1)
                used_rows.remove(row)
                used_rising_diagonals.remove(rising)
                used_falling_diagonals.remove(falling)

        search(0)
        output_values = [len(solutions)]
        for solution in solutions:
            output_values.extend(solution)
        output = b"".join(struct.pack("<q", item) for item in output_values)
        return len(output), output

    if encoding == "faster_perfect_numbers":
        if not 0 <= value <= 2_305_843_009_213_693_951:
            return -1, b""
        perfect_numbers = (6, 28, 496, 8128, 33_550_336, 8_589_869_056,
                           137_438_691_328, 2_305_843_008_139_952_128)
        output = b"".join(struct.pack("<q", number)
                           for number in perfect_numbers if number <= value)
        return len(output), output

    if encoding == "decimal_to_hex":
        if not 0 <= value <= 9_007_199_254_740_991:
            return -1, b""
        output = format(value, "X").encode("ascii")
        return len(output), output

    if encoding == "fizz_buzz":
        if not 1 <= value <= 512:
            return -1, b""
        tokens = []
        for number in range(1, value + 1):
            if number % 15 == 0:
                tokens.append("FizzBuzz")
            elif number % 3 == 0:
                tokens.append("Fizz")
            elif number % 5 == 0:
                tokens.append("Buzz")
            else:
                tokens.append(str(number))
        output = (" ".join(tokens) + " ").encode("ascii")
        return len(output), output

    if encoding == "goldbach_pair_i32le":
        if not 4 <= value <= 4096 or value % 2 != 0:
            return -1, b""

        def is_prime(candidate: int) -> bool:
            if candidate < 2:
                return False
            if candidate % 2 == 0:
                return candidate == 2
            divisor = 3
            while divisor <= candidate // divisor:
                if candidate % divisor == 0:
                    return False
                divisor += 2
            return True

        for first in range(value // 2 + 1):
            second = value - first
            if is_prime(first) and is_prime(second):
                output = struct.pack("<ii", first, second)
                return len(output), output
        raise ValueError("the bounded even Goldbach input has no prime pair")

    if encoding in {"hexagonal_numbers", "hexagonal_numbers_one_based"}:
        zero_based = encoding == "hexagonal_numbers"
        lower_bound = 1 if zero_based else 0
        if not lower_bound <= value <= 1024:
            return -1, b""
        first_index = 0 if zero_based else 1
        output = b"".join(struct.pack("<q", index * (2 * index - 1))
                           for index in range(first_index, first_index + value))
        return value, output
    if encoding == "int_to_string_packed":
        if value < 0:
            return -1, b""
        number, base_offset = divmod(value, 15)
        base = base_offset + 2
        if number > 65535:
            return -1, b""
        digits = b"0123456789abcdef"
        output = bytearray()
        while True:
            output.append(digits[number % base])
            number //= base
            if number == 0:
                break
        output.reverse()
        output.append(0)
        result = bytes(output)
        return len(result), result
    if encoding == "factorial_large_number":
        if not 0 <= value <= 100:
            return -1, b""
        result = 1
        for factor in range(2, value + 1):
            result *= factor
        output = str(result).encode("ascii")
        return len(output), output
    if encoding == "uint32_fixed_binary":
        if not 0 <= value <= 2**32 - 1:
            return -1, b""
        output = format(value, "032b").encode("ascii")
        return len(output), output
    if encoding == "count_and_say":
        if not 1 <= value <= 19:
            return -1, b""
        term = b"1"
        for _ in range(value - 1):
            next_term = bytearray()
            index = 0
            while index < len(term):
                end = index + 1
                while end < len(term) and term[end] == term[index]:
                    end += 1
                next_term.extend(str(end - index).encode("ascii"))
                next_term.append(term[index])
                index = end
            term = bytes(next_term)
        return len(term), term
    if encoding == "floyd_triangle":
        if not 0 <= value <= 90:
            return -1, b""
        count = value * (value + 1) // 2
        output = b"".join(struct.pack("<H", number) for number in range(1, count + 1))
        return len(output), output
    if encoding == "pascal_triangle_row":
        if not 0 <= value <= 33:
            return -1, b""
        output = b"".join(struct.pack("<I", math.comb(value, column))
                          for column in range(value + 1))
        return len(output), output
    if encoding == "roman":
        if not 1 <= value <= 3999:
            return -1, b""
        values = (1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1)
        symbols = (b"M", b"CM", b"D", b"CD", b"C", b"XC", b"L", b"XL", b"X", b"IX", b"V", b"IV", b"I")
        output = bytearray()
        for numeral_value, symbol in zip(values, symbols):
            count, value = divmod(value, numeral_value)
            output.extend(symbol * count)
        result = bytes(output)
        return len(result), result
    if encoding == "factors":
        if not 1 <= value <= 256:
            return -1, b""
        output = ",".join(str(divisor) for divisor in range(1, value + 1)
                          if value % divisor == 0).encode("ascii")
        return len(output), output
    if encoding == "prime_factors":
        if not 1 <= value <= 2**31 - 1:
            return -1, b""
        remaining = value
        divisor = 2
        factors = []
        while divisor <= remaining // divisor:
            while remaining % divisor == 0:
                factors.append(str(divisor))
                remaining //= divisor
            divisor += 1
        if remaining > 1:
            factors.append(str(remaining))
        output = ",".join(factors).encode("ascii")
        return len(output), output
    if encoding == "prime_factorization_pairs_u32le":
        if not 1 <= value <= 1_000_005:
            return -1, b""
        remaining = value
        divisor = 2
        pairs = bytearray()
        while divisor <= remaining // divisor:
            if remaining % divisor == 0:
                exponent = 0
                while remaining % divisor == 0:
                    remaining //= divisor
                    exponent += 1
                pairs.extend(struct.pack("<II", divisor, exponent))
            divisor += 1
        if remaining > 1:
            pairs.extend(struct.pack("<II", remaining, 1))
        output = bytes(pairs)
        return len(output), output
    if encoding == "factorize_pairs_u32le":
        if not 0 <= value <= 1_000_005:
            return -1, b""
        if value <= 1:
            pairs = [(value, 1)]
        else:
            remaining = value
            divisor = 2
            pairs = []
            while divisor <= remaining // divisor:
                if remaining % divisor == 0:
                    exponent = 0
                    while remaining % divisor == 0:
                        remaining //= divisor
                        exponent += 1
                    pairs.append((divisor, exponent))
                divisor += 1
            if remaining > 1:
                pairs.append((remaining, 1))
        output = b"".join(struct.pack("<II", factor, exponent)
                         for factor, exponent in pairs)
        return len(output), output
    if encoding == "juggler_sequence_i32le":
        if not 1 <= value <= 25:
            return -1, b""
        sequence = [value]
        while sequence[-1] != 1:
            current = sequence[-1]
            next_value = (math.isqrt(current) if current % 2 == 0
                          else math.isqrt(current * current * current))
            sequence.append(next_value)
        output = b"".join(struct.pack("<I", term) for term in sequence)
        return len(output), output
    if encoding == "narcissistic_numbers_be_i64":
        if value <= 0:
            return 0, b""
        if value > 100000:
            return -1, b""
        results = []
        for number in range(value):
            digits = str(number)
            if sum(int(digit) ** len(digits) for digit in digits) == number:
                results.append(number)
        output = b"".join(struct.pack(">q", number) for number in results)
        return len(output), output
    if encoding == "binary_coded_decimal":
        if not -(2**31) <= value <= 2**31 - 1:
            return -1, b""
        digits = str(max(0, value))
        output = ("0b" + "".join(f"{int(digit):04b}" for digit in digits)).encode("ascii")
        return len(output), output
    if encoding == "binary_twos_complement":
        if value > 0:
            return -1, b""
        if value == 0:
            output = b"0b0"
            return len(output), output
        bit_length = abs(value).bit_length()
        suffix = format((1 << bit_length) - abs(value), f"0{bit_length}b")
        output = ("0b1" + suffix).encode("ascii")
        return len(output), output
    if encoding == "prime_numbers":
        if not 0 <= value <= 80:
            return -1, b""
        primes = []
        for candidate in range(2, value + 1):
            divisor = 2
            while divisor <= candidate // divisor:
                if candidate % divisor == 0:
                    break
                divisor += 1
            else:
                primes.append(str(candidate))
        output = ",".join(primes).encode("ascii")
        return len(output), output
    if encoding == "first_n_primes":
        if not 0 <= value <= 20:
            return -1, b""
        primes = []
        candidate = 2
        while len(primes) < value:
            divisor = 2
            while divisor <= candidate // divisor:
                if candidate % divisor == 0:
                    break
                divisor += 1
            else:
                primes.append(str(candidate))
            candidate += 1
        output = ",".join(primes).encode("ascii")
        return len(output), output
    if encoding == "palindrome_primes_i32le":
        if value > 16:
            return -1, b""
        if value <= 0:
            return 0, b""

        def is_prime(candidate: int) -> bool:
            if candidate < 2:
                return False
            divisor = 2
            while divisor <= candidate // divisor:
                if candidate % divisor == 0:
                    return False
                divisor += 1
            return True

        def is_palindrome(candidate: int) -> bool:
            original = candidate
            reversed_value = 0
            while candidate > 0:
                reversed_value = reversed_value * 10 + candidate % 10
                candidate //= 10
            return original == reversed_value

        output = bytearray(struct.pack("<I", 2))
        count = 1
        candidate = 3
        while count < value:
            if is_palindrome(candidate) and is_prime(candidate):
                output.extend(struct.pack("<I", candidate))
                count += 1
            candidate += 2
        result = bytes(output)
        return len(result), result
    if value < 0:
        return -1, b""
    formats = {2: "b", 8: "o", 16: "x"}
    if encoding not in formats:
        raise ValueError(f"unsupported output encoding: {encoding}")
    output = format(value, formats[encoding]).encode("ascii")
    return len(output), output


def fnv1a(data: bytes) -> int:
    result = 14695981039346656037
    for value in data:
        result = ((result ^ value) * 1099511628211) & ((1 << 64) - 1)
    return result


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
    if manifest.get("family") != "i64_scalar_bytes_output":
        parser.error("build manifest must declare the i64_scalar_bytes_output ABI family")
    algorithm, language = manifest["algorithm"], manifest["language"]
    source = (ROOT / manifest["source_path"]).resolve()
    source.relative_to(ROOT)
    binary = manifest["binaries"]["i64_scalar_bytes_output_runner"]
    executable = Path(binary["path"])
    runner = ROOT / "benchmarks/harness/i64_scalar_bytes_output_runner.c"
    if (sha256_file(source) != manifest["source_sha256"]
            or sha256_file(executable) != binary["sha256"]
            or sha256_file(runner) != binary["harness_sha256"]):
        parser.error("source, runner, or binary changed since the recorded build; rebuild first")

    letter = algorithm[0] if algorithm[0].isalpha() else "0-9"
    workload_path = args.workload or ROOT / "benchmarks" / letter / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != algorithm
            or workload.get("measurement", {}).get("comparison_model") != "i64_scalar_bytes_output_call"):
        parser.error("workload does not match the built scalar byte-output algorithm")
    encoding = (algorithm if algorithm in {"hexagonal_numbers", "hexagonal_numbers_one_based",
                                          "decimal_to_hex", "decimal_to_gray",
                                          "n_queens_backtracking_csharp",
                                          "faster_perfect_numbers", "fizz_buzz", "magicdiamondpattern"}
                else workload.get("input", {}).get("encoding", workload.get("input", {}).get("radix", 2)))
    if algorithm in {"evalloop", "huffbench"}:
        encoding = workload.get("output", {}).get("encoding")
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
        value = case.get("input_value")
        if type(value) is not int or not -(2**63) <= value < 2**63:
            raise ValueError(f"invalid signed 64-bit scalar in {case['id']}")
        required_result, required_output = expected_output(value, encoding)
        output_capacity = case.get("output_capacity", case.get("workspace_bytes",
                                                                  len(required_output) or MAX_OUTPUT_BYTES))
        if type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_BYTES:
            raise ValueError(f"invalid output capacity in {case['id']}")
        output_is_null = case.get("output_is_null", False)
        if type(output_is_null) is not bool:
            raise ValueError(f"output_is_null must be a boolean in {case['id']}")
        if required_result < 0:
            expected_result, expected = required_result, b""
        elif output_is_null:
            zero_byte_result = workload.get("output", {}).get("zero_byte_output_result")
            stream_sieve_empty_exception = (
                encoding == "stream_sieve_primes_i32le"
                and not required_output
                and required_result == 0
                and workload.get("output", {}).get("null_output_exception")
                    == "n<=0 succeeds with zero bytes even when the output pointer is null."
            )
            if (not required_output and type(zero_byte_result) is int
                    and required_result == zero_byte_result) or stream_sieve_empty_exception:
                expected_result, expected = required_result, required_output
            else:
                null_result = workload.get("output", {}).get("null_output_result", -2)
                if type(null_result) is not int:
                    raise ValueError("null_output_result must be an integer for null-output fixtures")
                expected_result, expected = null_result, b""
        elif output_capacity < len(required_output):
            expected_result = case.get("capacity_error_result", -2)
            expected = b""
        else:
            expected_result, expected = required_result, required_output
        expected_matches = (case.get("expected_output_hex") == expected.hex()
                            if "expected_output_hex" in case
                            else case.get("expected_output") == expected.decode("ascii"))
        if case.get("expected_result") != expected_result or not expected_matches:
            raise ValueError(f"workload oracle mismatch for {case['id']}")
        encoded = expected.hex() if expected else "-"
        command = [str(executable), str(value), str(expected_result), encoded, str(output_capacity),
                   str(int(output_is_null)),
                   str(samples), str(warmups), str(repetitions)]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode:
            raise SystemExit(f"scalar byte-output runner failed for {case['id']}: {completed.stderr}")
        raw = json.loads(completed.stdout)
        expected_checksum = (fnv1a(expected) * repetitions * samples) & ((1 << 64) - 1)
        if (raw["observed_result"] != expected_result or len(raw["samples_ns"]) != samples
                or raw["result_checksum"] != expected_checksum):
            raise ValueError(f"scalar byte-output runner returned an invalid result for {case['id']}")
        records.append({"schema_version": "1.0.0", "run_id": run_id, "algorithm": algorithm,
                        "implementation": implementation, "environment": environment,
                        "workload": {"id": workload["id"], "spec_sha256": sha256_file(workload_path),
                                     "input_length": None, "input_value": value,
                                     "case": case["id"], "target": None, "output_capacity": output_capacity,
                                     "output_is_null": output_is_null,
                                     "expected_result": expected_result},
                        "measurement": {"timer": "C clock() process CPU time",
                                        "timer_resolution_ns": raw["timer_resolution_ns"],
                                        "comparison_model": "i64_scalar_bytes_output_call",
                                        "target_comparisons_per_sample": None,
                                        "warmup_rounds": warmups, "repetitions_per_sample": repetitions,
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
