#!/usr/bin/env python3
"""Verify scalar-to-byte-buffer ports against independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import heapq
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_scalar_bytes_output import MAX_OUTPUT_BYTES
from run_i64_scalar_bytes_output import expected_output as _runner_expected_output
from ary3_oracle import INVALID_RESULT as ARY3_INVALID_RESULT
from ary3_oracle import MAX_LENGTH as ARY3_MAX_LENGTH
from ary3_oracle import MAX_OUTPUT_BYTES as ARY3_MAX_OUTPUT_BYTES
from ary3_oracle import OUTPUT_ERROR as ARY3_OUTPUT_ERROR
from stream_sieve_oracle import I32_MIN as STREAM_SIEVE_MIN_COUNT
from stream_sieve_oracle import MAX_COUNT as STREAM_SIEVE_MAX_COUNT
from stream_sieve_oracle import MAX_OUTPUT_BYTES as STREAM_SIEVE_MAX_OUTPUT_BYTES
from shootout_random_oracle import INVALID_RESULT as SHOOTOUT_RANDOM_INVALID_RESULT
from shootout_random_oracle import MAX_CALL_COUNT as SHOOTOUT_RANDOM_MAX_CALL_COUNT
from shootout_random_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES
from shootout_random_oracle import MIN_CALL_COUNT as SHOOTOUT_RANDOM_MIN_CALL_COUNT
from shootout_random_oracle import OUTPUT_ERROR as SHOOTOUT_RANDOM_OUTPUT_ERROR
from shootout_hello_oracle import INVALID_RESULT as SHOOTOUT_HELLO_INVALID_RESULT
from shootout_hello_oracle import MAX_CALLS as SHOOTOUT_HELLO_MAX_CALLS
from shootout_hello_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_HELLO_MAX_OUTPUT_BYTES
from shootout_hello_oracle import MIN_CALLS as SHOOTOUT_HELLO_MIN_CALLS
from shootout_hello_oracle import OUTPUT_ERROR as SHOOTOUT_HELLO_OUTPUT_ERROR
from shootout_lists_oracle import INVALID_RESULT as SHOOTOUT_LISTS_INVALID_RESULT
from shootout_lists_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_LISTS_MAX_OUTPUT_BYTES
from shootout_lists_oracle import MAX_RUNS as SHOOTOUT_LISTS_MAX_RUNS
from shootout_lists_oracle import MIN_RUNS as SHOOTOUT_LISTS_MIN_RUNS
from shootout_lists_oracle import OUTPUT_ERROR as SHOOTOUT_LISTS_OUTPUT_ERROR
from shootout_strcat_oracle import INVALID_RESULT as SHOOTOUT_STRCAT_INVALID_RESULT
from shootout_strcat_oracle import MAX_APPEND_COUNT as SHOOTOUT_STRCAT_MAX_APPEND_COUNT
from shootout_strcat_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_STRCAT_MAX_OUTPUT_BYTES
from shootout_strcat_oracle import MIN_APPEND_COUNT as SHOOTOUT_STRCAT_MIN_APPEND_COUNT
from shootout_strcat_oracle import OUTPUT_ERROR as SHOOTOUT_STRCAT_OUTPUT_ERROR
from shootout_methcall_oracle import INVALID_RESULT as SHOOTOUT_METHCALL_INVALID_RESULT
from shootout_methcall_oracle import MAX_CALLS as SHOOTOUT_METHCALL_MAX_CALLS
from shootout_methcall_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_METHCALL_MAX_OUTPUT_BYTES
from shootout_methcall_oracle import MIN_CALLS as SHOOTOUT_METHCALL_MIN_CALLS
from shootout_methcall_oracle import OUTPUT_ERROR as SHOOTOUT_METHCALL_OUTPUT_ERROR
from shootout_objinst_oracle import INVALID_RESULT as SHOOTOUT_OBJINST_INVALID_RESULT
from shootout_objinst_oracle import MAX_N as SHOOTOUT_OBJINST_MAX_N
from shootout_objinst_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES
from shootout_objinst_oracle import MIN_N as SHOOTOUT_OBJINST_MIN_N
from shootout_objinst_oracle import OUTPUT_ERROR as SHOOTOUT_OBJINST_OUTPUT_ERROR
from benchmarkgame_recursive_oracle import INVALID_RESULT as BENCHMARKGAME_RECURSIVE_INVALID_RESULT
from benchmarkgame_recursive_oracle import MAX_N as BENCHMARKGAME_RECURSIVE_MAX_N
from benchmarkgame_recursive_oracle import MAX_OUTPUT_BYTES as BENCHMARKGAME_RECURSIVE_MAX_OUTPUT_BYTES
from benchmarkgame_recursive_oracle import MIN_N as BENCHMARKGAME_RECURSIVE_MIN_N
from benchmarkgame_recursive_oracle import OUTPUT_ERROR as BENCHMARKGAME_RECURSIVE_OUTPUT_ERROR
from almabench_oracle import INVALID_RESULT as ALMABENCH_INVALID_RESULT
from almabench_oracle import MAX_DAYS as ALMABENCH_MAX_DAYS
from almabench_oracle import MAX_OUTPUT_BYTES as ALMABENCH_MAX_OUTPUT_BYTES
from almabench_oracle import MIN_DAYS as ALMABENCH_MIN_DAYS
from almabench_oracle import OUTPUT_ERROR as ALMABENCH_OUTPUT_ERROR
from queens_oracle import INVALID_RESULT as QUEENS_INVALID_RESULT
from queens_oracle import MAX_N as QUEENS_MAX_N
from queens_oracle import MAX_OUTPUT_BYTES as QUEENS_MAX_OUTPUT_BYTES
from queens_oracle import OUTPUT_ERROR as QUEENS_OUTPUT_ERROR
from npb_is_oracle import INVALID_RESULT as NPB_IS_INVALID_RESULT
from npb_is_oracle import MAX_OUTPUT_BYTES as NPB_IS_MAX_OUTPUT_BYTES
from npb_is_oracle import MAX_PASSES as NPB_IS_MAX_PASSES
from npb_is_oracle import OUTPUT_ERROR as NPB_IS_OUTPUT_ERROR
from stanford_queens_oracle import INVALID_RESULT as STANFORD_QUEENS_INVALID_RESULT
from stanford_queens_oracle import MAX_OUTPUT_BYTES as STANFORD_QUEENS_MAX_OUTPUT_BYTES
from stanford_queens_oracle import MAX_RUNS as STANFORD_QUEENS_MAX_RUNS
from stanford_queens_oracle import MIN_RUNS as STANFORD_QUEENS_MIN_RUNS
from stanford_queens_oracle import OUTPUT_ERROR as STANFORD_QUEENS_OUTPUT_ERROR
from evalloop_oracle import INVALID_RESULT as EVALLOOP_INVALID_RESULT
from evalloop_oracle import MAX_OUTPUT_BYTES as EVALLOOP_MAX_OUTPUT_BYTES
from evalloop_oracle import MAX_PASSES as EVALLOOP_MAX_PASSES
from evalloop_oracle import OUTPUT_ERROR as EVALLOOP_OUTPUT_ERROR
from mcgill_misr_oracle import INVALID_RESULT as MCGILL_MISR_INVALID_RESULT
from mcgill_misr_oracle import MAX_EXPERIMENTS as MCGILL_MISR_MAX_EXPERIMENTS
from mcgill_misr_oracle import MAX_OUTPUT_BYTES as MCGILL_MISR_MAX_OUTPUT_BYTES
from mcgill_misr_oracle import MIN_EXPERIMENTS as MCGILL_MISR_MIN_EXPERIMENTS
from mcgill_misr_oracle import OUTPUT_ERROR as MCGILL_MISR_OUTPUT_ERROR

ALGORITHMS = ("decimal_to_binary", "decimal_to_octal", "decimal_to_hexadecimal", "integer_to_roman",
              "pascal_triangle_row", "floyd_triangle", "harmonic_series", "butterfly_pattern",
              "magicdiamondpattern", "prime_factorial", "stream_sieve", "ary3",
              "shootout_random", "benchmarkgame_recursive",
              "almabench", "queens", "npb_is",
              "stanford_queens", "shootout_hello",
              "shootout_lists", "shootout_strcat",
              "shootout_methcall", "shootout_objinst", "evalloop", "mcgill_misr", "huffbench")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
HUFFBENCH_MIN_PASSES = 1
HUFFBENCH_MAX_PASSES = 30
HUFFBENCH_MAX_OUTPUT_BYTES = 52


def _huffbench_verifier_expected_output(passes: int) -> tuple[int, bytes]:
    if not HUFFBENCH_MIN_PASSES <= passes <= HUFFBENCH_MAX_PASSES:
        return -1, b""
    seed = 1325
    alphabet = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ012345"
    data = bytearray()
    for _ in range(4096):
        seed ^= 123459876
        quotient = seed // 127773
        seed = 16807 * (seed - quotient * 127773) - 2836 * quotient
        if seed < 0:
            seed += 2147483647
        data.append(alphabet[seed % 32])
        seed ^= 123459876

    frequencies: dict[int, int] = {}
    for byte in data:
        frequencies[byte] = frequencies.get(byte, 0) + 1
    forest = list(frequencies.values())
    heapq.heapify(forest)
    encoded_bits = 0
    while len(forest) > 1:
        merged = heapq.heappop(forest) + heapq.heappop(forest)
        encoded_bits += merged
        heapq.heappush(forest, merged)
    compressed_length = (encoded_bits + 7) // 8
    checksum = sum(data) & 0xFFFFFFFF
    output = (f"Huffbench passes={passes} compressed={compressed_length} "
              f"checksum={checksum}\n").encode("ascii")
    return len(output), output


def expected_output(value: int, encoding: int | str = 2) -> tuple[int, bytes]:
    if encoding == "huffbench_summary_ascii":
        return _huffbench_verifier_expected_output(value)
    return _runner_expected_output(value, encoding)


def expected_call(value: int, encoding: int | str, output_capacity: int,
                  output_is_null: bool, workload: dict,
                  capacity_error_result: int) -> tuple[int, bytes]:
    result, output = expected_output(value, encoding)
    if result < 0:
        return result, b""
    if output_is_null:
        output_spec = workload.get("output", {})
        zero_byte_result = output_spec.get("zero_byte_output_result")
        stream_sieve_empty_exception = (
            encoding == "stream_sieve_primes_i32le"
            and output_spec.get("null_output_exception")
                == "n<=0 succeeds with zero bytes even when the output pointer is null."
        )
        if (not output and result == 0
                and (zero_byte_result == 0 or stream_sieve_empty_exception)):
            return result, output
        null_result = output_spec.get("null_output_result", -2)
        if type(null_result) is not int:
            raise ValueError("null_output_result must be an integer for null-output cases")
        return null_result, b""
    if output_capacity < len(output):
        if type(capacity_error_result) is not int:
            raise ValueError("capacity error result must be an integer")
        return capacity_error_result, b""
    return result, output


def corpus(workload: dict) -> tuple[str, int]:
    encoding = workload.get("input", {}).get("encoding", workload.get("input", {}).get("radix", 2))
    if workload.get("algorithm") in {"evalloop", "huffbench"}:
        encoding = workload.get("output", {}).get("encoding")
    capacity_error_result = workload.get("output", {}).get(
        "capacity_error_result", workload.get("output", {}).get("insufficient_capacity_result", -2))

    elif encoding == "shootout_random_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/random/random.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/random/info.sh"
        )
        required_case_ids = {
            "one_call", "two_calls", "ten_calls", "thousand_calls", "maximum_bounded_calls",
            "zero_calls", "negative_calls", "calls_above_bound", "signed_64_minimum",
            "signed_64_maximum", "insufficient_capacity", "null_output",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-random-bounded-decimal-v1"
                or workload.get("algorithm") != "shootout_random"
                or workload.get("function_symbol") != "shootout_random"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/random/random.c",
                    "symbol": "gen_random and main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written algorithm ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/random/info.sh",
                    "bench_name": "random",
                    "source_files": ["random.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The launcher supplies no arguments. Without SMALL_PROBLEM_SIZE, random.c defaults to LENGTH=400000000; with that compile-time macro it defaults to 40000000. For positive argv count n, main performs n generator calls total: n-1 in the loop and one for the printed value. The generator starts with static state 42 and applies (state*3877+29573)%139968 before returning 100.0*state/139968. The suite preserves the recurrence and final nine-place decimal output while bounding n to 1..1000000.",
                    "upstream_default_call_count": 400000000,
                    "small_problem_size_default_call_count": 40000000,
                    "profile_minimum_call_count": SHOOTOUT_RANDOM_MIN_CALL_COUNT,
                    "profile_maximum_call_count": SHOOTOUT_RANDOM_MAX_CALL_COUNT,
                    "source_output_format": 'printf("%.9f\\n", value)',
                    "invalid_source_case": "The suite rejects nonpositive and above-bound values. The upstream argc/atoi path does not define the suite's bounded scalar contract.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_random_ascii",
                    "meaning": "Number of LCG transitions from initial state 42; the final random value is returned as source-style decimal ASCII.",
                    "minimum": SHOOTOUT_RANDOM_MIN_CALL_COUNT,
                    "maximum": SHOOTOUT_RANDOM_MAX_CALL_COUNT,
                    "invalid_result": SHOOTOUT_RANDOM_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "Nine digits after the decimal point followed by LF.",
                    "definition": "After n transitions, format 100.0*state/139968 to nine fractional decimal digits and append LF. No intermediate values or final state are returned.",
                    "maximum_output_bytes": SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_RANDOM_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_RANDOM_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_RANDOM_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES != 13
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_random workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_random" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_random README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        maximum_case = fixtures["maximum_bounded_calls"]
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["one_call"].get("input_value") != SHOOTOUT_RANDOM_MIN_CALL_COUNT
                or fixtures["one_call"].get("expected_result") != len(expected_output(
                    SHOOTOUT_RANDOM_MIN_CALL_COUNT, encoding)[1])
                or maximum_case.get("input_value") != SHOOTOUT_RANDOM_MAX_CALL_COUNT
                or maximum_case.get("expected_result") != len(expected_output(
                    SHOOTOUT_RANDOM_MAX_CALL_COUNT, encoding)[1])
                or capacity_case.get("input_value") != SHOOTOUT_RANDOM_MIN_CALL_COUNT
                or capacity_case.get("output_capacity") != SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES - 1
                or capacity_case.get("expected_result") != SHOOTOUT_RANDOM_OUTPUT_ERROR
                or null_case.get("input_value") != SHOOTOUT_RANDOM_MIN_CALL_COUNT
                or null_case.get("output_capacity") != SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_RANDOM_OUTPUT_ERROR
                or fixtures["zero_calls"].get("input_value") != 0
                or fixtures["negative_calls"].get("input_value") != -1
                or fixtures["calls_above_bound"].get("input_value") != SHOOTOUT_RANDOM_MAX_CALL_COUNT + 1
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX):
            raise ValueError("shootout_random workload is missing its reviewed boundary/output fixtures")
    elif encoding == "benchmarkgame_recursive_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/recursive.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/info.sh"
        )
        required_case_ids = {
            "minimum_profile_n", "launcher_default", "negative_n", "n_above_bound",
            "signed_64_minimum", "signed_64_maximum", "insufficient_capacity", "null_output",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-benchmarkgame-recursive-bounded-stdout-v1"
                or workload.get("algorithm") != "benchmarkgame_recursive"
                or workload.get("function_symbol") != "benchmarkgame_recursive"
                or workload.get("description") != "Bounded port of all five recursive calls and output lines in BenchmarkGame/recursive/recursive.c."
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "BenchmarkGame/recursive/recursive.c",
                    "symbol": "main, ack, fib, fibFP, tak, takFP",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written algorithm ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "BenchmarkGame/recursive/info.sh",
                    "bench_name": "recursive",
                    "source_files": ["recursive.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The source main hard-codes n=10 and prints five results in order: integer Ackermann(3,n+1), floating recursive Fibonacci(28+n), integer Takeuchi(3n,2n,n), integer Fibonacci(3), and floating Takeuchi(3.0,2.0,1.0). The suite exposes the source's n as a bounded scalar from 0 through 10; n=10 reproduces the launcher profile. Recursive benchmark implementations remain uncached, and each measurement uses a single call because fibFP grows exponentially.",
                    "launcher_default_n": 10,
                    "profile_minimum_n": BENCHMARKGAME_RECURSIVE_MIN_N,
                    "profile_maximum_n": BENCHMARKGAME_RECURSIVE_MAX_N,
                    "launcher_default_stdout": "Ack(3,11): 16381\nFib(38.0): 63245986.0\nTak(30,20,10): 10\nFib(3): 3\nTak(3.0,2.0,1.0): 2.0\n",
                    "invalid_suite_input": "The suite returns -1 for n outside 0..10; the pinned main does not parse a command-line n.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "benchmarkgame_recursive_ascii",
                    "meaning": "The source's n parameter; n controls all three variable recursive calls and n=10 is the pinned launcher profile.",
                    "minimum": BENCHMARKGAME_RECURSIVE_MIN_N,
                    "maximum": BENCHMARKGAME_RECURSIVE_MAX_N,
                    "invalid_result": BENCHMARKGAME_RECURSIVE_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "The exact five source printf lines, in source order, with LF line endings.",
                    "maximum_output_bytes": BENCHMARKGAME_RECURSIVE_MAX_OUTPUT_BYTES,
                    "invalid_result": BENCHMARKGAME_RECURSIVE_INVALID_RESULT,
                    "null_output_result": BENCHMARKGAME_RECURSIVE_OUTPUT_ERROR,
                    "insufficient_capacity_result": BENCHMARKGAME_RECURSIVE_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 1,
                    "warmup_rounds": 0,
                    "repetitions_per_sample": 1,
                }
                or BENCHMARKGAME_RECURSIVE_MIN_N != 0
                or BENCHMARKGAME_RECURSIVE_MAX_N != 10
                or BENCHMARKGAME_RECURSIVE_MAX_OUTPUT_BYTES != 89
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("benchmarkgame_recursive workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "b" / "benchmarkgame_recursive" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("benchmarkgame_recursive README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        minimum_case = fixtures["minimum_profile_n"]
        launcher_case = fixtures["launcher_default"]
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        launcher_output = workload["source_bound"]["launcher_default_stdout"].encode("ascii")
        if (minimum_case.get("input_value") != BENCHMARKGAME_RECURSIVE_MIN_N
                or minimum_case.get("expected_result") != len(expected_output(
                    BENCHMARKGAME_RECURSIVE_MIN_N, encoding)[1])
                or launcher_case.get("input_value") != BENCHMARKGAME_RECURSIVE_MAX_N
                or launcher_case.get("expected_result") != len(launcher_output)
                or launcher_case.get("expected_output") != launcher_output.decode("ascii")
                or capacity_case.get("input_value") != BENCHMARKGAME_RECURSIVE_MIN_N
                or capacity_case.get("output_capacity") != len(expected_output(
                    BENCHMARKGAME_RECURSIVE_MIN_N, encoding)[1]) - 1
                or capacity_case.get("expected_result") != BENCHMARKGAME_RECURSIVE_OUTPUT_ERROR
                or null_case.get("input_value") != BENCHMARKGAME_RECURSIVE_MIN_N
                or null_case.get("output_capacity") != BENCHMARKGAME_RECURSIVE_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != BENCHMARKGAME_RECURSIVE_OUTPUT_ERROR
                or fixtures["negative_n"].get("input_value") != -1
                or fixtures["n_above_bound"].get("input_value") != BENCHMARKGAME_RECURSIVE_MAX_N + 1
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX):
            raise ValueError("benchmarkgame_recursive workload is missing its reviewed boundary/output fixtures")
    elif encoding == "npb_is_class_w_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/is/is.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/is/info.sh"
        )
        required_case_ids = {
            "one_pass", "two_passes", "class_w_ten_pass_profile", "zero_passes_invalid",
            "above_profile_invalid", "signed_64_minimum_invalid", "signed_64_maximum_invalid",
            "insufficient_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-npb-is-class-w-bounded-v1"
                or workload.get("algorithm") != "npb_is"
                or workload.get("function_symbol") != "npb_is"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "NPB-serial/is/is.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The source grants permission to use, copy, distribute, and modify for any purpose, requests derived work to reference NAS Parallel Benchmarks 3.3, and includes an as-is warranty disclaimer; ports are independently written.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "NPB-serial/is/info.sh",
                    "bench_name": "is",
                    "source_files": ["is.c"],
                    "default_compile_flags": [],
                    "class_w_compile_flag": "-DSMALL_PROBLEM_SIZE",
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "profile": "class W selected by SMALL_PROBLEM_SIZE",
                    "total_keys": 1048576,
                    "max_key_exclusive": 65536,
                    "num_buckets": 1024,
                    "iterations": 10,
                    "seed": 314159265,
                    "lcg_multiplier": 1220703125,
                    "lcg_modulus": 70368744177664,
                    "random_draws_per_key": 4,
                    "key_indices": [357773, 934767, 875723, 898999, 404505],
                    "baseline_ranks": [1249, 11698, 1039987, 1043896, 1048018],
                    "profile_minimum_passes": 1,
                    "profile_maximum_passes": NPB_IS_MAX_PASSES,
                    "verification": "Each pass checks five class-W partial ranks; a full sorted-order check contributes one more verification. A successful prefix run reports 5*pass_count+1.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "npb_is_class_w_ascii",
                    "meaning": "Number of class-W rank passes to execute after the source-equivalent rank(1) warm-up.",
                    "minimum": 1,
                    "maximum": NPB_IS_MAX_PASSES,
                    "invalid_result": NPB_IS_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "npb_is_partial_ranks_csv_ascii",
                    "format": "five comma-separated decimal partial ranks and LF per pass, then decimal verification count and LF",
                    "definition": "Each pass emits the count of keys strictly less than each of the five source-selected key values, in source index order. The final line is the total successful partial and full verification count.",
                    "maximum_output_bytes": NPB_IS_MAX_OUTPUT_BYTES,
                    "invalid_result": NPB_IS_INVALID_RESULT,
                    "null_output_result": NPB_IS_OUTPUT_ERROR,
                    "insufficient_capacity_result": NPB_IS_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or NPB_IS_MAX_PASSES != 10
                or NPB_IS_MAX_OUTPUT_BYTES != 353
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("npb_is workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "n" / "npb_is" / "README.md").read_text(encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("npb_is README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, passes in (("one_pass", 1), ("two_passes", 2),
                                ("class_w_ten_pass_profile", NPB_IS_MAX_PASSES)):
            expected_result, expected = expected_output(passes, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != passes
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output_hex", "").lower() != expected.hex()):
                raise ValueError(f"npb_is fixture {case_id} does not match its oracle")
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["zero_passes_invalid"].get("input_value") != 0
                or fixtures["above_profile_invalid"].get("input_value") != NPB_IS_MAX_PASSES + 1
                or fixtures["signed_64_minimum_invalid"].get("input_value") != I64_MIN
                or fixtures["signed_64_maximum_invalid"].get("input_value") != I64_MAX
                or capacity_case.get("input_value") != 1
                or capacity_case.get("output_capacity") != len(expected_output(1, encoding)[1]) - 1
                or capacity_case.get("expected_result") != NPB_IS_OUTPUT_ERROR
                or null_case.get("input_value") != NPB_IS_MAX_PASSES
                or null_case.get("output_capacity") != NPB_IS_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != NPB_IS_OUTPUT_ERROR):
            raise ValueError("npb_is workload is missing its reviewed boundary/output fixtures")
    elif encoding == "evalloop_stdout_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/evalloop/evalloop.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/evalloop/info.sh"
        )
        required_case_ids = {
            "zero_passes", "one_source_buffer_evaluation", "two_source_buffer_evaluations",
            "maximum_bounded_profile", "below_profile", "above_profile",
            "signed_64_minimum", "signed_64_maximum", "short_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-misc-evalloop-bounded-v1"
                or workload.get("algorithm") != "evalloop"
                or workload.get("function_symbol") != "evalloop"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Misc/evalloop/evalloop.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Misc/evalloop/info.sh",
                    "bench_name": "evalloop",
                    "source_files": ["evalloop.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "Initialize 2,047 opcodes as i % 31 + 1 followed by opcode 0; each evaluation starts at the first opcode, dispatches every nonzero command, adds its opcode to a uint32 accumulator, and exits on 0.",
                    "source_buffer_size": 2048,
                    "source_nonzero_commands_per_evaluation": 2047,
                    "source_default_passes": 100000,
                    "source_default_sum": 3273700000,
                    "profile_minimum_passes": 0,
                    "profile_maximum_passes": EVALLOOP_MAX_PASSES,
                    "sum_per_evaluation": 32737,
                    "output_format": r"Sum: <unsigned decimal uint32>\n",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "evalloop_passes",
                    "meaning": "Number of times to evaluate the generated opcode buffer.",
                    "minimum": 0,
                    "maximum": EVALLOOP_MAX_PASSES,
                    "invalid_result": EVALLOOP_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "evalloop_stdout_ascii",
                    "definition": "The accumulated uint32 sum formatted as `Sum: `, unsigned decimal digits, and LF.",
                    "maximum_output_bytes": EVALLOOP_MAX_OUTPUT_BYTES,
                    "invalid_result": EVALLOOP_INVALID_RESULT,
                    "null_output_result": EVALLOOP_OUTPUT_ERROR,
                    "insufficient_capacity_result": EVALLOOP_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or EVALLOOP_MAX_PASSES != 1000
                or EVALLOOP_MAX_OUTPUT_BYTES != 14
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("evalloop workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "e" / "evalloop" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("evalloop README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, value in (("zero_passes", 0), ("one_source_buffer_evaluation", 1),
                               ("two_source_buffer_evaluations", 2),
                               ("maximum_bounded_profile", EVALLOOP_MAX_PASSES)):
            fixture = fixtures[case_id]
            expected_result, expected = expected_output(value, encoding)
            if (fixture.get("input_value") != value
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output", "").encode("ascii") != expected):
                raise ValueError(f"evalloop valid fixture {case_id} does not match its oracle")
        for case_id, value in (("below_profile", -1),
                               ("above_profile", EVALLOOP_MAX_PASSES + 1),
                               ("signed_64_minimum", I64_MIN),
                               ("signed_64_maximum", I64_MAX)):
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != value
                    or fixture.get("expected_result") != EVALLOOP_INVALID_RESULT
                    or fixture.get("expected_output") != ""):
                raise ValueError(f"evalloop invalid fixture {case_id} is incorrect")
        capacity_case = fixtures["short_capacity"]
        null_case = fixtures["null_output"]
        if (capacity_case.get("input_value") != 1
                or capacity_case.get("output_capacity") != 10
                or capacity_case.get("expected_result") != EVALLOOP_OUTPUT_ERROR
                or capacity_case.get("expected_output") != ""
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != EVALLOOP_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != EVALLOOP_OUTPUT_ERROR
                or null_case.get("expected_output") != ""):
            raise ValueError("evalloop workload is missing its reviewed boundary/output fixtures")
    elif encoding == "mcgill_misr_report_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/misr/misr.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/misr/info.sh"
        )
        required_case_ids = {
            "minimum_profile_short_buffer", "maximum_profile_short_buffer",
            "minimum_profile_null_output", "zero_experiments_invalid",
            "negative_experiments_invalid", "above_profile_invalid",
            "signed_64_minimum_invalid", "signed_64_maximum_invalid",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-mcgill-misr-bounded-report-v1"
                or workload.get("algorithm") != "mcgill_misr"
                or workload.get("function_symbol") != "mcgill_misr"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "McGill/misr/misr.c",
                    "symbol": "main, simulate, init, create_link_list",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written algorithm ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "McGill/misr/info.sh",
                    "bench_name": "misr",
                    "source_files": ["misr.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The launcher supplies no arguments. The source fixes reg_len=num_vect=10 and prob=0.25, uses default structure 1000000000 and seed48 words {1,0,0}, and runs 100000 experiments (30000 with SMALL_PROBLEM_SIZE). Each experiment copies the current good register into the faulty register, executes ten vectors through the two MISRs, then records whether any of the ten visible cells differ. The suite uses experiments as its scalar and bounds it to 1..1000. It preserves the POSIX 48-bit lrand48 recurrence, source register/update order, and two-line report while bounding runtime.",
                    "upstream_default_experiments": 100000,
                    "small_problem_size_experiments": 30000,
                    "register_length": 10,
                    "vectors_per_experiment": 10,
                    "fault_probability": 0.25,
                    "feedback_structure": "1000000000",
                    "seed_words": [1, 0, 0],
                    "random_recurrence": "state=(0x5DEECE66D*state+0xB) mod 2^48; lrand48=state>>17",
                    "profile_minimum_experiments": MCGILL_MISR_MIN_EXPERIMENTS,
                    "profile_maximum_experiments": MCGILL_MISR_MAX_EXPERIMENTS,
                    "source_output_format": "header printf followed by reg_len, num_vect, prob, num_times, structure, seeds, and (num_times-num_true)/num_times with %.8e",
                    "invalid_suite_case": "The suite rejects experiment counts outside 1..1000; the pinned main does not parse a runtime experiment count.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "mcgill_misr_report_ascii",
                    "meaning": "Number of independent ten-vector MISR experiments, with source register, probability, structure, and seeds fixed to launcher defaults.",
                    "minimum": MCGILL_MISR_MIN_EXPERIMENTS,
                    "maximum": MCGILL_MISR_MAX_EXPERIMENTS,
                    "invalid_result": MCGILL_MISR_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "The original report header, a space-prefixed parameter line, and LF endings.",
                    "definition": "The two source printf outputs, including the space after the first LF; the final field is the fraction of experiments whose good and faulty visible registers match, formatted in scientific notation with eight fractional digits.",
                    "maximum_output_bytes": MCGILL_MISR_MAX_OUTPUT_BYTES,
                    "invalid_result": MCGILL_MISR_INVALID_RESULT,
                    "null_output_result": MCGILL_MISR_OUTPUT_ERROR,
                    "insufficient_capacity_result": MCGILL_MISR_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or MCGILL_MISR_MIN_EXPERIMENTS != 1
                or MCGILL_MISR_MAX_EXPERIMENTS != 1000
                or MCGILL_MISR_MAX_OUTPUT_BYTES != 123
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("McGill MISR workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "m" / "mcgill_misr" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("McGill MISR README is missing its pinned source or launcher link")
    elif encoding == "shootout_hello_stdout_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hello/hello.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hello/info.sh"
        )
        required_case_ids = {
            "source_single_call", "zero_calls", "negative_calls", "extra_call_not_in_source",
            "signed_64_minimum", "signed_64_maximum", "insufficient_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-hello-single-call-v1"
                or workload.get("algorithm") != "shootout_hello"
                or workload.get("function_symbol") != "shootout_hello"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/hello/hello.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/hello/info.sh",
                    "bench_name": "hello",
                    "source_files": ["hello.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "main executes puts(\"hello world\\n\") exactly once; puts appends a second LF after the newline already in the string.",
                    "launcher_default_calls": 1,
                    "profile_minimum_calls": SHOOTOUT_HELLO_MIN_CALLS,
                    "profile_maximum_calls": SHOOTOUT_HELLO_MAX_CALLS,
                    "source_stdout": "hello world\n\n",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_hello_calls",
                    "meaning": "One-valued selector representing the source's single puts call.",
                    "minimum": SHOOTOUT_HELLO_MIN_CALLS,
                    "maximum": SHOOTOUT_HELLO_MAX_CALLS,
                    "invalid_result": SHOOTOUT_HELLO_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "shootout_hello_stdout_ascii",
                    "definition": "The exact bytes hello world followed by two LF bytes.",
                    "maximum_output_bytes": SHOOTOUT_HELLO_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_HELLO_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_HELLO_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_HELLO_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_HELLO_MIN_CALLS != 1
                or SHOOTOUT_HELLO_MAX_CALLS != 1
                or SHOOTOUT_HELLO_MAX_OUTPUT_BYTES != 13
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_hello workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_hello" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_hello README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        expected_result, expected = expected_output(1, encoding)
        fixture = fixtures["source_single_call"]
        if (fixture.get("input_value") != 1
                or fixture.get("expected_result") != expected_result
                or fixture.get("expected_output", "").encode("ascii") != expected):
            raise ValueError("shootout_hello source fixture does not match its oracle")
        for case_id, value in (("zero_calls", 0), ("negative_calls", -1),
                               ("extra_call_not_in_source", 2),
                               ("signed_64_minimum", I64_MIN),
                               ("signed_64_maximum", I64_MAX)):
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != value
                    or fixture.get("expected_result") != SHOOTOUT_HELLO_INVALID_RESULT
                    or fixture.get("expected_output") != ""):
                raise ValueError(f"shootout_hello invalid fixture {case_id} is incorrect")
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (capacity_case.get("input_value") != 1
                or capacity_case.get("output_capacity") != SHOOTOUT_HELLO_MAX_OUTPUT_BYTES - 1
                or capacity_case.get("expected_result") != SHOOTOUT_HELLO_OUTPUT_ERROR
                or capacity_case.get("expected_output") != ""
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != SHOOTOUT_HELLO_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_HELLO_OUTPUT_ERROR
                or null_case.get("expected_output") != ""):
            raise ValueError("shootout_hello workload is missing its reviewed boundary/output fixtures")
    elif encoding == "shootout_lists_stdout_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/lists/lists.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/lists/info.sh"
        )
        required_case_ids = {
            "zero_passes", "one_pass", "two_passes", "maximum_profile_runs",
            "negative_runs", "above_profile_runs", "signed_64_minimum",
            "signed_64_maximum", "short_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-lists-bounded-v1"
                or workload.get("algorithm") != "shootout_lists"
                or workload.get("function_symbol") != "shootout_lists"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/lists/lists.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/lists/info.sh",
                    "bench_name": "lists",
                    "source_files": ["lists.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "Each pass creates a 100-element list and copy, verifies equality, drains the copy through a third list in both directions, reverses the original, and verifies equality and endpoints. The C main repeats this pass n times and prints the last result, or zero when n is zero.",
                    "list_size": 100,
                    "launcher_default_runs": 3000000,
                    "small_problem_size_runs": 300000,
                    "profile_minimum_runs": SHOOTOUT_LISTS_MIN_RUNS,
                    "profile_maximum_runs": SHOOTOUT_LISTS_MAX_RUNS,
                    "zero_run_stdout": "0\n",
                    "positive_run_stdout": "100\n",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_lists_runs",
                    "meaning": "Number of complete source list-test passes; the suite bounds this to avoid the launcher’s multi-million-pass default.",
                    "minimum": SHOOTOUT_LISTS_MIN_RUNS,
                    "maximum": SHOOTOUT_LISTS_MAX_RUNS,
                    "invalid_result": SHOOTOUT_LISTS_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "shootout_lists_stdout_ascii",
                    "definition": "ASCII 0 followed by LF for zero passes, or ASCII 100 followed by LF for one or more passes.",
                    "maximum_output_bytes": SHOOTOUT_LISTS_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_LISTS_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_LISTS_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_LISTS_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_LISTS_MIN_RUNS != 0
                or SHOOTOUT_LISTS_MAX_RUNS != 10000
                or SHOOTOUT_LISTS_MAX_OUTPUT_BYTES != 4
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_lists workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_lists" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_lists README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, runs in (("zero_passes", 0), ("one_pass", 1), ("two_passes", 2),
                              ("maximum_profile_runs", SHOOTOUT_LISTS_MAX_RUNS)):
            expected_result, expected = expected_output(runs, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != runs
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output") != expected.decode("ascii")):
                raise ValueError(f"shootout_lists fixture {case_id} does not match its oracle")
        capacity_case = fixtures["short_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["negative_runs"].get("input_value") != -1
                or fixtures["negative_runs"].get("expected_result") != SHOOTOUT_LISTS_INVALID_RESULT
                or fixtures["above_profile_runs"].get("input_value") != SHOOTOUT_LISTS_MAX_RUNS + 1
                or fixtures["above_profile_runs"].get("expected_result") != SHOOTOUT_LISTS_INVALID_RESULT
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_minimum"].get("expected_result") != SHOOTOUT_LISTS_INVALID_RESULT
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX
                or fixtures["signed_64_maximum"].get("expected_result") != SHOOTOUT_LISTS_INVALID_RESULT
                or capacity_case.get("input_value") != 1
                or capacity_case.get("output_capacity") != 3
                or capacity_case.get("expected_result") != SHOOTOUT_LISTS_OUTPUT_ERROR
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != SHOOTOUT_LISTS_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_LISTS_OUTPUT_ERROR):
            raise ValueError("shootout_lists workload is missing its reviewed boundary/output fixtures")
    elif encoding == "shootout_strcat_stdout_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/strcat/strcat.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/strcat/info.sh"
        )
        required_case_ids = {
            "zero_appends", "one_append", "five_before_first_growth", "six_growth_boundary",
            "ten_before_next_growth", "eleven_growth_boundary", "maximum_profile",
            "negative_count", "count_above_profile", "signed_64_minimum", "signed_64_maximum",
            "insufficient_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-strcat-bounded-v1"
                or workload.get("algorithm") != "shootout_strcat"
                or workload.get("function_symbol") != "shootout_strcat"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/strcat/strcat.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/strcat/info.sh",
                    "bench_name": "strcat",
                    "source_files": ["strcat.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "Each loop appends the six bytes hello followed by LF; after all appends, main prints strlen as decimal ASCII followed by LF. Buffer capacity starts at 32 and doubles when fewer than seven bytes remain.",
                    "launcher_default_calls": 10000000,
                    "profile_minimum_calls": SHOOTOUT_STRCAT_MIN_APPEND_COUNT,
                    "profile_maximum_calls": SHOOTOUT_STRCAT_MAX_APPEND_COUNT,
                    "source_stdout_formula": "decimal(6 * append_count) followed by LF",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_strcat_append_count",
                    "meaning": "Number of six-byte hello-newline appends.",
                    "minimum": SHOOTOUT_STRCAT_MIN_APPEND_COUNT,
                    "maximum": SHOOTOUT_STRCAT_MAX_APPEND_COUNT,
                    "invalid_result": SHOOTOUT_STRCAT_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "shootout_strcat_stdout_ascii",
                    "definition": "Decimal representation of six times append_count, followed by one LF byte.",
                    "maximum_output_bytes": SHOOTOUT_STRCAT_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_STRCAT_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_STRCAT_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_STRCAT_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_STRCAT_MIN_APPEND_COUNT != 0
                or SHOOTOUT_STRCAT_MAX_APPEND_COUNT != 4096
                or SHOOTOUT_STRCAT_MAX_OUTPUT_BYTES != 6
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_strcat workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_strcat" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_strcat README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, appends in (("zero_appends", 0), ("one_append", 1),
                                 ("five_before_first_growth", 5), ("six_growth_boundary", 6),
                                 ("ten_before_next_growth", 10), ("eleven_growth_boundary", 11),
                                 ("maximum_profile", SHOOTOUT_STRCAT_MAX_APPEND_COUNT)):
            expected_result, expected = expected_output(appends, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != appends
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output") != expected.decode("ascii")):
                raise ValueError(f"shootout_strcat fixture {case_id} does not match its oracle")
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["negative_count"].get("input_value") != -1
                or fixtures["negative_count"].get("expected_result") != SHOOTOUT_STRCAT_INVALID_RESULT
                or fixtures["count_above_profile"].get("input_value") != SHOOTOUT_STRCAT_MAX_APPEND_COUNT + 1
                or fixtures["count_above_profile"].get("expected_result") != SHOOTOUT_STRCAT_INVALID_RESULT
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_minimum"].get("expected_result") != SHOOTOUT_STRCAT_INVALID_RESULT
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX
                or fixtures["signed_64_maximum"].get("expected_result") != SHOOTOUT_STRCAT_INVALID_RESULT
                or capacity_case.get("input_value") != 2
                or capacity_case.get("output_capacity") != 2
                or capacity_case.get("expected_result") != SHOOTOUT_STRCAT_OUTPUT_ERROR
                or null_case.get("input_value") != 2
                or null_case.get("output_capacity") != 3
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_STRCAT_OUTPUT_ERROR):
            raise ValueError("shootout_strcat workload is missing its reviewed boundary/output fixtures")
    elif encoding == "shootout_methcall_stdout_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/methcall/methcall.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/methcall/info.sh"
        )
        required_case_ids = {
            "zero_calls", "one_call", "two_calls", "nth_toggle_first_flip",
            "nth_toggle_after_reset", "two_nth_toggle_flips", "negative_call_count_zero_iterations",
            "maximum_profile_calls", "below_profile_minimum", "above_profile_maximum",
            "signed_64_minimum", "signed_64_maximum", "short_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-methcall-bounded-v1"
                or workload.get("algorithm") != "shootout_methcall"
                or workload.get("function_symbol") != "shootout_methcall"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/methcall/methcall.c",
                    "symbol": "Toggle, NthToggle, main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/methcall/info.sh",
                    "bench_name": "methcall",
                    "source_files": ["methcall.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The first Toggle starts true and flips on every activation. The second NthToggle starts true, increments its counter on each activation, flips at count_max=3, and resets its counter to zero. The source prints the final value of each loop using puts on strings that already end in LF.",
                    "launcher_default_calls": 500000000,
                    "small_problem_size_calls": 50000000,
                    "profile_minimum_calls": SHOOTOUT_METHCALL_MIN_CALLS,
                    "profile_maximum_calls": SHOOTOUT_METHCALL_MAX_CALLS,
                    "negative_calls_perform_zero_iterations": True,
                    "toggle_flip_period": 1,
                    "nth_toggle_flip_period": 3,
                    "puts_appends_lf_after_embedded_lf": True,
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_methcall_calls",
                    "meaning": "Call count supplied to each source loop; negative values also execute zero iterations, as in the C loop condition.",
                    "minimum": SHOOTOUT_METHCALL_MIN_CALLS,
                    "maximum": SHOOTOUT_METHCALL_MAX_CALLS,
                    "invalid_result": SHOOTOUT_METHCALL_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "shootout_methcall_stdout_ascii",
                    "definition": "Two final state words in source order, each followed by two LF bytes because puts appends a newline to a string that already contains one.",
                    "maximum_output_bytes": SHOOTOUT_METHCALL_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_METHCALL_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_METHCALL_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_METHCALL_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_METHCALL_MIN_CALLS != -100000
                or SHOOTOUT_METHCALL_MAX_CALLS != 100000
                or SHOOTOUT_METHCALL_MAX_OUTPUT_BYTES != 14
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_methcall workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_methcall" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_methcall README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, calls in (("zero_calls", 0), ("one_call", 1), ("two_calls", 2),
                               ("nth_toggle_first_flip", 3), ("nth_toggle_after_reset", 4),
                               ("two_nth_toggle_flips", 6),
                               ("negative_call_count_zero_iterations", -1),
                               ("maximum_profile_calls", SHOOTOUT_METHCALL_MAX_CALLS)):
            expected_result, expected = expected_output(calls, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != calls
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output") != expected.decode("ascii")):
                raise ValueError(f"shootout_methcall fixture {case_id} does not match its oracle")
        capacity_case = fixtures["short_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["below_profile_minimum"].get("input_value") != SHOOTOUT_METHCALL_MIN_CALLS - 1
                or fixtures["below_profile_minimum"].get("expected_result") != SHOOTOUT_METHCALL_INVALID_RESULT
                or fixtures["above_profile_maximum"].get("input_value") != SHOOTOUT_METHCALL_MAX_CALLS + 1
                or fixtures["above_profile_maximum"].get("expected_result") != SHOOTOUT_METHCALL_INVALID_RESULT
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_minimum"].get("expected_result") != SHOOTOUT_METHCALL_INVALID_RESULT
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX
                or fixtures["signed_64_maximum"].get("expected_result") != SHOOTOUT_METHCALL_INVALID_RESULT
                or capacity_case.get("input_value") != 3
                or capacity_case.get("output_capacity") != SHOOTOUT_METHCALL_MAX_OUTPUT_BYTES - 1
                or capacity_case.get("expected_result") != SHOOTOUT_METHCALL_OUTPUT_ERROR
                or null_case.get("input_value") != 0
                or null_case.get("output_capacity") != SHOOTOUT_METHCALL_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_METHCALL_OUTPUT_ERROR):
            raise ValueError("shootout_methcall workload is missing its reviewed boundary/output fixtures")
    elif encoding == "shootout_objinst_stdout_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/objinst/objinst.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/objinst/info.sh"
        )
        required_case_ids = {
            "negative_n_skips_constructor_loops", "zero_n_fixed_dispatch_output",
            "one_additional_object_of_each_type", "maximum_profile_constructor_count",
            "below_profile", "above_profile", "signed_64_minimum", "signed_64_maximum",
            "short_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-objinst-bounded-v1"
                or workload.get("algorithm") != "shootout_objinst"
                or workload.get("function_symbol") != "shootout_objinst"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/objinst/objinst.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/objinst/info.sh",
                    "bench_name": "objinst",
                    "source_files": ["objinst.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "Construct and destroy one initial Toggle, make five stored-callback activation/value calls, construct/destroy n more Toggles, emit a blank line, construct and destroy one NthToggle, make eight callback calls, then construct/destroy n more NthToggles. Negative n naturally skips both for-loops.",
                    "launcher_default_constructions_per_type": 70000000,
                    "small_problem_size_constructions_per_type": 7000000,
                    "profile_minimum_n": SHOOTOUT_OBJINST_MIN_N,
                    "profile_maximum_n": SHOOTOUT_OBJINST_MAX_N,
                    "source_stdout": "false\ntrue\nfalse\ntrue\nfalse\n\ntrue\ntrue\nfalse\nfalse\nfalse\ntrue\ntrue\ntrue\n",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_objinst_n",
                    "meaning": "Number of additional Toggle constructions and, separately, additional NthToggle constructions; negative values execute zero iterations in each source loop.",
                    "minimum": SHOOTOUT_OBJINST_MIN_N,
                    "maximum": SHOOTOUT_OBJINST_MAX_N,
                    "invalid_result": SHOOTOUT_OBJINST_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "shootout_objinst_stdout_ascii",
                    "definition": "Five Toggle state lines, one blank line, then eight NthToggle state lines, each ending in LF.",
                    "maximum_output_bytes": SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_OBJINST_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_OBJINST_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_OBJINST_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_OBJINST_MIN_N != -100000
                or SHOOTOUT_OBJINST_MAX_N != 100000
                or SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES != 72
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_objinst workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_objinst" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_objinst README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, n in (("negative_n_skips_constructor_loops", SHOOTOUT_OBJINST_MIN_N),
                           ("zero_n_fixed_dispatch_output", 0),
                           ("one_additional_object_of_each_type", 1),
                           ("maximum_profile_constructor_count", SHOOTOUT_OBJINST_MAX_N)):
            expected_result, expected = expected_output(n, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != n
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output") != expected.decode("ascii")):
                raise ValueError(f"shootout_objinst fixture {case_id} does not match its oracle")
        capacity_case = fixtures["short_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["below_profile"].get("input_value") != SHOOTOUT_OBJINST_MIN_N - 1
                or fixtures["below_profile"].get("expected_result") != SHOOTOUT_OBJINST_INVALID_RESULT
                or fixtures["above_profile"].get("input_value") != SHOOTOUT_OBJINST_MAX_N + 1
                or fixtures["above_profile"].get("expected_result") != SHOOTOUT_OBJINST_INVALID_RESULT
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_minimum"].get("expected_result") != SHOOTOUT_OBJINST_INVALID_RESULT
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX
                or fixtures["signed_64_maximum"].get("expected_result") != SHOOTOUT_OBJINST_INVALID_RESULT
                or capacity_case.get("input_value") != 1
                or capacity_case.get("output_capacity") != SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES - 1
                or capacity_case.get("expected_result") != SHOOTOUT_OBJINST_OUTPUT_ERROR
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_OBJINST_OUTPUT_ERROR):
            raise ValueError("shootout_objinst workload is missing its reviewed boundary/output fixtures")
    elif encoding == "stanford_queens_runs":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Queens/Queens.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Queens/info.sh"
        )
        required_case_ids = {
            "one_pass", "two_passes", "launcher_default", "zero_passes",
            "negative_passes", "passes_above_bound", "signed_64_minimum",
            "signed_64_maximum", "insufficient_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-stanford-queens-bounded-passes-v1"
                or workload.get("algorithm") != "stanford_queens"
                or workload.get("function_symbol") != "stanford_queens"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Stanford/Queens/Queens.c",
                    "symbol": "Try, Doit, Queens, main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Stanford/Queens/info.sh",
                    "bench_name": "Queens",
                    "source_files": ["Queens.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "Each Queens(run) invokes Doit 50 times, and each Doit initializes the eight-column and diagonal availability arrays before calling Try at row 1. Try tries columns 1 through 8 in ascending order, descends while marking both diagonals and backtracks failed branches. The source stops at the first solution, emits an error line only if no solution is found, then prints run+1. main invokes runs 0 through 99.",
                    "launcher_default_runs": 100,
                    "searches_per_pass": 50,
                    "board_size": 8,
                    "profile_minimum_runs": STANFORD_QUEENS_MIN_RUNS,
                    "profile_maximum_runs": STANFORD_QUEENS_MAX_RUNS,
                    "source_stdout_prefix": "For run count k, perform 50 full first-solution eight-queens searches per pass and print pass ordinals 1 through k, one decimal ordinal per line.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "stanford_queens_runs",
                    "meaning": "Number of source Queens passes to perform, from the launcher's 100-pass loop.",
                    "minimum": STANFORD_QUEENS_MIN_RUNS,
                    "maximum": STANFORD_QUEENS_MAX_RUNS,
                    "invalid_result": STANFORD_QUEENS_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "stanford_queens_stdout_ascii",
                    "definition": "The source error line only if an eight-queens search fails, followed by one pass ordinal and LF per requested pass. The fixed search is solvable.",
                    "maximum_output_bytes": STANFORD_QUEENS_MAX_OUTPUT_BYTES,
                    "invalid_result": STANFORD_QUEENS_INVALID_RESULT,
                    "null_output_result": STANFORD_QUEENS_OUTPUT_ERROR,
                    "insufficient_capacity_result": STANFORD_QUEENS_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or STANFORD_QUEENS_MIN_RUNS != 1
                or STANFORD_QUEENS_MAX_RUNS != 100
                or STANFORD_QUEENS_MAX_OUTPUT_BYTES != 292
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("stanford_queens workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "stanford_queens" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("stanford_queens README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, runs in (("one_pass", 1), ("two_passes", 2),
                              ("launcher_default", STANFORD_QUEENS_MAX_RUNS)):
            expected_result, expected = expected_output(runs, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != runs
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output", "").encode("ascii") != expected):
                raise ValueError(f"stanford_queens fixture {case_id} does not match its oracle")
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["zero_passes"].get("input_value") != 0
                or fixtures["zero_passes"].get("expected_result") != STANFORD_QUEENS_INVALID_RESULT
                or fixtures["negative_passes"].get("input_value") != -1
                or fixtures["negative_passes"].get("expected_result") != STANFORD_QUEENS_INVALID_RESULT
                or fixtures["passes_above_bound"].get("input_value") != STANFORD_QUEENS_MAX_RUNS + 1
                or fixtures["passes_above_bound"].get("expected_result") != STANFORD_QUEENS_INVALID_RESULT
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_minimum"].get("expected_result") != STANFORD_QUEENS_INVALID_RESULT
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX
                or fixtures["signed_64_maximum"].get("expected_result") != STANFORD_QUEENS_INVALID_RESULT
                or capacity_case.get("input_value") != 1
                or capacity_case.get("output_capacity") != len(expected_output(1, encoding)[1]) - 1
                or capacity_case.get("expected_result") != STANFORD_QUEENS_OUTPUT_ERROR
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != STANFORD_QUEENS_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != STANFORD_QUEENS_OUTPUT_ERROR):
            raise ValueError("stanford_queens workload is missing its reviewed boundary/output fixtures")
    elif encoding == "mcgill_queens_count_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/queens/queens.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/queens/info.sh"
        )
        required_case_ids = {
            "one_queen_singular_count", "two_queens_no_solutions", "four_queens_two_solutions",
            "eight_queens_standard_count", "launcher_default_fourteen_queens",
            "insufficient_capacity", "null_output_positive", "zero_invalid",
            "above_profile_invalid", "int64_min_invalid", "int64_max_invalid",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-mcgill-queens-count-only-ascii-v1"
                or workload.get("algorithm") != "queens"
                or workload.get("function_symbol") != "queens"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "McGill/queens/queens.c",
                    "symbol": "main/find",
                    "url": source_url,
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "McGill/queens/info.sh",
                    "bench_name": "queens",
                    "source_files": ["queens.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The launcher runs queens.c without options. main defaults to n=14, sets printing=0 and findall=1, searches every placement without symmetry pruning, and emits a board-size heading followed by the total solution count. The suite accepts n=1..14, preserving the launcher's default workload at the upper bound while limiting the source's broader 1..100 domain.",
                    "source_default_n": 14,
                    "source_input_range": [1, 100],
                    "suite_input_range": [1, 14],
                    "search_order": "Place one queen per rank; try files left-to-right; recurse immediately when file and diagonal owner entries are not occupied by an earlier rank.",
                    "symmetry_reduction": False,
                    "printing": False,
                    "find_all_solutions": True,
                    "stdout_format": [
                        "printf(\"%d queen%s on a %dx%d board...\\n\")",
                        "...there is 1 solution\\n when the count is one; otherwise ...there are %ld solutions\\n",
                    ],
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "mcgill_queens_count_ascii",
                    "meaning": "Board dimension n for the count-only queens search.",
                    "minimum": 1,
                    "maximum": QUEENS_MAX_N,
                    "invalid_result": QUEENS_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "mcgill_queens_count_stdout_ascii",
                    "definition": "The source header line followed by its singular or plural total-solution line; no board layout is printed.",
                    "maximum_output_bytes": QUEENS_MAX_OUTPUT_BYTES,
                    "invalid_result": QUEENS_INVALID_RESULT,
                    "null_output_result": QUEENS_OUTPUT_ERROR,
                    "insufficient_capacity_result": QUEENS_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or QUEENS_MAX_N != 14
                or QUEENS_MAX_OUTPUT_BYTES != 80
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("queens workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "q" / "queens" / "README.md").read_text(encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("queens README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, n in (("one_queen_singular_count", 1), ("two_queens_no_solutions", 2),
                           ("four_queens_two_solutions", 4), ("eight_queens_standard_count", 8),
                           ("launcher_default_fourteen_queens", 14)):
            expected_result, expected = expected_output(n, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != n
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output_hex", "").lower() != expected.hex()):
                raise ValueError(f"queens fixture {case_id} does not match its oracle")
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output_positive"]
        if (fixtures["zero_invalid"].get("input_value") != 0
                or fixtures["above_profile_invalid"].get("input_value") != QUEENS_MAX_N + 1
                or fixtures["int64_min_invalid"].get("input_value") != I64_MIN
                or fixtures["int64_max_invalid"].get("input_value") != I64_MAX
                or capacity_case.get("input_value") != 4
                or capacity_case.get("output_capacity") != len(expected_output(4, encoding)[1]) - 1
                or capacity_case.get("expected_result") != QUEENS_OUTPUT_ERROR
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != len(expected_output(1, encoding)[1])
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != QUEENS_OUTPUT_ERROR):
            raise ValueError("queens workload is missing its reviewed boundary/output fixtures")
    elif encoding == "almabench_ephemeris_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/almabench/almabench.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/almabench/info.sh"
        )
        required_case_ids = {
            "first_day", "second_day", "small_problem_size_default", "launcher_default",
            "zero_days", "negative_days", "days_above_bound", "signed_64_minimum",
            "signed_64_maximum", "insufficient_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-coyotebench-almabench-bounded-ephemeris-v1"
                or workload.get("algorithm") != "almabench"
                or workload.get("function_symbol") != "almabench"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "CoyoteBench/almabench/almabench.c",
                    "symbol": "planetpv, radecdist, main",
                    "url": source_url,
                    "license_note": "The referenced C source is public domain (No rights reserved); these are independently written ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "CoyoteBench/almabench/info.sh",
                    "bench_name": "almabench",
                    "source_files": ["almabench.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The launcher has no runtime options. The source defaults to 20 passes and 36525 daily dates; SMALL_PROBLEM_SIZE selects one pass and 3652 dates. Every pass resets the date and computes the same ephemeris, so the suite performs one bounded pass and returns the final date output. It calculates all eight planets for each date from J2000+1 through J2000+days and prints only the final date, with three %f fields per planet.",
                    "upstream_default_passes": 20,
                    "small_problem_size_passes": 1,
                    "upstream_default_days": 36525,
                    "small_problem_size_default_days": 3652,
                    "profile_minimum_days": ALMABENCH_MIN_DAYS,
                    "profile_maximum_days": ALMABENCH_MAX_DAYS,
                    "launcher_default_final_julian_day": 2488070.0,
                    "source_output_format": "printf(\"%f %f %f\\n\", right_ascension_hours, declination_degrees, distance_au)",
                    "invalid_suite_case": "The suite rejects day counts outside 1..36525; the pinned launcher does not parse a runtime day count.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "almabench_ephemeris_ascii",
                    "meaning": "Number of daily ephemeris calculations from J2000+1 through J2000+days; the final day’s eight planet rows are returned.",
                    "minimum": ALMABENCH_MIN_DAYS,
                    "maximum": ALMABENCH_MAX_DAYS,
                    "invalid_result": ALMABENCH_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "Eight lines in planet order Mercury through Neptune, each containing right ascension hours, declination degrees, and distance AU at six fractional digits, separated by one ASCII space and terminated by LF.",
                    "definition": "The final day’s ephemeris for all eight planets, formatted as three six-decimal values per source printf line.",
                    "maximum_output_bytes": ALMABENCH_MAX_OUTPUT_BYTES,
                    "invalid_result": ALMABENCH_INVALID_RESULT,
                    "null_output_result": ALMABENCH_OUTPUT_ERROR,
                    "insufficient_capacity_result": ALMABENCH_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or ALMABENCH_MIN_DAYS != 1
                or ALMABENCH_MAX_DAYS != 36525
                or ALMABENCH_MAX_OUTPUT_BYTES != 248
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("almabench workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "a" / "almabench" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("almabench README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in cases}
        for case_id, days in (("first_day", 1), ("second_day", 2),
                              ("small_problem_size_default", 3652), ("launcher_default", 36525)):
            expected_result, expected = expected_output(days, encoding)
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != days
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output") != expected.decode("ascii")):
                raise ValueError(f"almabench fixture {case_id} does not match its oracle")
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["zero_days"].get("input_value") != 0
                or fixtures["negative_days"].get("input_value") != -1
                or fixtures["days_above_bound"].get("input_value") != ALMABENCH_MAX_DAYS + 1
                or fixtures["signed_64_minimum"].get("input_value") != I64_MIN
                or fixtures["signed_64_maximum"].get("input_value") != I64_MAX
                or capacity_case.get("input_value") != ALMABENCH_MIN_DAYS
                or capacity_case.get("output_capacity") != len(expected_output(
                    ALMABENCH_MIN_DAYS, encoding)[1]) - 1
                or capacity_case.get("expected_result") != ALMABENCH_OUTPUT_ERROR
                or null_case.get("input_value") != ALMABENCH_MIN_DAYS
                or null_case.get("output_capacity") != ALMABENCH_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != ALMABENCH_OUTPUT_ERROR):
            raise ValueError("almabench workload is missing its reviewed boundary/output fixtures")
    elif encoding == "shootout_ary3_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ary3/ary3.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ary3/info.sh"
        )
        required_case_ids = {
            "one_element", "two_elements", "ten_elements", "large_representative",
            "maximum_length", "zero_length_invalid", "negative_length_invalid",
            "above_bound_invalid", "int64_min_invalid", "insufficient_capacity", "null_output",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-ary3-repeated-array-addition-ascii-v1"
                or workload.get("algorithm") != "ary3"
                or workload.get("function_symbol") != "ary3"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/ary3/ary3.c",
                    "symbol": "main",
                    "url": source_url,
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/ary3/info.sh",
                    "bench_name": "ary3",
                    "source_files": ["ary3.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_ary3_ascii",
                    "meaning": "Positive array length n; x[i] is initialized to i+1.",
                    "minimum": 1,
                    "maximum": ARY3_MAX_LENGTH,
                    "invalid_result": ARY3_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "printf(\"%d %d\\n\"): final y[0], one space, final y[n-1], newline",
                    "definition": "Exact ASCII bytes produced by the 1000 reverse-index passes; for the bounded profile, y[0]=1000 and y[n-1]=1000*n.",
                    "maximum_output_bytes": ARY3_MAX_OUTPUT_BYTES,
                    "invalid_result": ARY3_INVALID_RESULT,
                    "null_output_result": ARY3_OUTPUT_ERROR,
                    "insufficient_capacity_result": ARY3_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 10,
                }
                or ARY3_MAX_OUTPUT_BYTES != 13
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("ary3 workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "a" / "ary3" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("ary3 README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        maximum_case = fixtures["maximum_length"]
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (maximum_case.get("input_value") != ARY3_MAX_LENGTH
                or maximum_case.get("expected_result") != ARY3_MAX_OUTPUT_BYTES
                or capacity_case.get("input_value") != 10
                or capacity_case.get("output_capacity") != 10
                or capacity_case.get("expected_result") != ARY3_OUTPUT_ERROR
                or null_case.get("input_value") != 1
                or null_case.get("output_capacity") != 10
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != ARY3_OUTPUT_ERROR
                or fixtures["zero_length_invalid"].get("input_value") != 0
                or fixtures["above_bound_invalid"].get("input_value") != ARY3_MAX_LENGTH + 1):
            raise ValueError("ary3 workload is missing maximum, null, capacity, or range fixtures")
    elif encoding == "stream_sieve_primes_i32le":
        source_url = (
            "https://github.com/TheAlgorithms/Scala/blob/"
            "de555349d5effb87962d3116eb08c9f374065112/"
            "src/main/scala/Mathematics/StreamSieve.scala"
        )
        required_case_ids = {
            "int32_min_empty", "negative_empty", "zero_empty", "null_output_empty",
            "null_output_nonempty", "one_prime", "two_primes", "ten_primes",
            "sixty_four_prime_prefix", "maximum_100_primes", "insufficient_capacity",
            "below_int32_range", "above_int32_range", "above_count_limit",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "stream-sieve-prime-prefix-i32le-v1"
                or workload.get("algorithm") != "stream_sieve"
                or workload.get("function_symbol") != "stream_sieve"
                or workload.get("pinned_source") != {
                    "repository": "TheAlgorithms/Scala",
                    "commit": "de555349d5effb87962d3116eb08c9f374065112",
                    "path": "src/main/scala/Mathematics/StreamSieve.scala",
                    "symbol": "StreamSieve.allPrimes/getPrimeNumbers",
                    "url": source_url,
                }
                or workload.get("input") != {
                    "minimum": STREAM_SIEVE_MIN_COUNT,
                    "maximum": STREAM_SIEVE_MAX_COUNT,
                    "encoding": "stream_sieve_primes_i32le",
                    "meaning": "Return the first n primes from a shared lazily extended prime prefix; n<=0 is empty.",
                    "out_of_range_result": -1,
                }
                or workload.get("output") != {
                    "kind": "little_endian_signed_32_bit_prime_array",
                    "definition": "The first max(n,0) primes in ascending order, encoded as one signed i32 each.",
                    "success_result": "4*n bytes for positive n, otherwise 0",
                    "maximum_bytes": STREAM_SIEVE_MAX_OUTPUT_BYTES,
                    "null_output_result": -2,
                    "insufficient_capacity_result": -2,
                    "no_write_on_error": True,
                    "null_output_exception": "n<=0 succeeds with zero bytes even when the output pointer is null.",
                }
                or workload.get("workspace") is not None
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 9,
                    "warmup_rounds": 2,
                    "repetitions_per_sample": 100,
                }
                or STREAM_SIEVE_MIN_COUNT != -(2 ** 31)
                or STREAM_SIEVE_MAX_COUNT != 100
                or STREAM_SIEVE_MAX_OUTPUT_BYTES != 4 * STREAM_SIEVE_MAX_COUNT
                or len(case_ids) != 14
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("stream_sieve workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "stream_sieve" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme:
            raise ValueError("stream_sieve README is missing its pinned Scala source link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        maximum_case = fixtures["maximum_100_primes"]
        empty_null_case = fixtures["null_output_empty"]
        positive_null_case = fixtures["null_output_nonempty"]
        capacity_case = fixtures["insufficient_capacity"]
        if (maximum_case.get("input_value") != STREAM_SIEVE_MAX_COUNT
                or maximum_case.get("expected_result") != STREAM_SIEVE_MAX_OUTPUT_BYTES
                or maximum_case.get("output_capacity") != STREAM_SIEVE_MAX_OUTPUT_BYTES
                or len(maximum_case.get("expected_output_hex", ""))
                    != 2 * STREAM_SIEVE_MAX_OUTPUT_BYTES
                or empty_null_case.get("input_value") != 0
                or empty_null_case.get("output_is_null") is not True
                or empty_null_case.get("expected_result") != 0
                or empty_null_case.get("output_capacity") != 0
                or positive_null_case.get("input_value") != 1
                or positive_null_case.get("output_is_null") is not True
                or positive_null_case.get("expected_result") != -2
                or positive_null_case.get("output_capacity") != 4
                or capacity_case.get("input_value") != 10
                or capacity_case.get("output_capacity") != 39
                or capacity_case.get("expected_result") != -2
                or fixtures["below_int32_range"].get("input_value") != STREAM_SIEVE_MIN_COUNT - 1
                or fixtures["above_int32_range"].get("input_value") != 2 ** 31
                or fixtures["above_count_limit"].get("input_value") != STREAM_SIEVE_MAX_COUNT + 1):
            raise ValueError("stream_sieve workload is missing maximum, null, capacity, or range fixtures")
    elif encoding == "huffbench_summary_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/huffbench/huffbench.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/huffbench/info.sh"
        )
        required_case_ids = {
            "one_round", "two_rounds", "pinned_launcher_round_count", "below_profile",
            "above_profile", "signed_64_minimum", "signed_64_maximum", "exact_capacity",
            "one_byte_short_capacity", "null_output",
        }
        cases = workload.get("cases", [])
        case_ids = [case.get("id") for case in cases]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-coyote-huffbench-bounded-v1"
                or workload.get("algorithm") != "huffbench"
                or workload.get("function_symbol") != "coyote_huffbench"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "CoyoteBench/huffbench/huffbench.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The source header says: ‘No rights reserved. This is public domain software, for use by anyone.’ Attribution and the original notice are retained in LICENSE.txt.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "CoyoteBench/huffbench/info.sh",
                    "bench_name": "huffbench",
                    "source_files": ["huffbench.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "Generate uppercase letters and digits from the source Park-Miller generator seeded at 1325, build the source-style frequency heap and Huffman code table, encode the data MSB-first, then decode it back into the original buffer. The pinned default runs 30 rounds over 10,000,000 bytes. The suite profile fixes the bounded input at 4,096 bytes and accepts 1 through 30 rounds.",
                    "source_default_data_bytes": 10000000,
                    "source_default_rounds": 30,
                    "profile_data_bytes": 4096,
                    "profile_minimum_rounds": HUFFBENCH_MIN_PASSES,
                    "profile_maximum_rounds": HUFFBENCH_MAX_PASSES,
                    "generator_seed": 1325,
                    "alphabet": "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345",
                    "summary_format": r"Huffbench passes=<rounds> compressed=<byte_count> checksum=<sum of decoded bytes modulo 2^32>\n",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "huffbench_round_count",
                    "meaning": "Number of complete source compression/decompression rounds over the fixed 4,096-byte generated data buffer.",
                    "minimum": HUFFBENCH_MIN_PASSES,
                    "maximum": HUFFBENCH_MAX_PASSES,
                    "invalid_result": -1,
                }
                or workload.get("output") != {
                    "kind": "source_kernel_summary_ascii",
                    "encoding": "huffbench_summary_ascii",
                    "definition": "The pass count, compressed byte count from the final round, and modulo-2^32 sum of decoded bytes, formatted as ASCII with a final LF.",
                    "maximum_output_bytes": HUFFBENCH_MAX_OUTPUT_BYTES,
                    "invalid_result": -1,
                    "null_output_result": -2,
                    "insufficient_capacity_result": -2,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or HUFFBENCH_MIN_PASSES != 1
                or HUFFBENCH_MAX_PASSES != 30
                or HUFFBENCH_MAX_OUTPUT_BYTES != 52
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("huffbench workload metadata does not match its pinned bounded contract")
        package = ROOT / "benchmarks" / "h" / "huffbench"
        readme = (package / "README.md").read_text(encoding="utf-8")
        license_text = (package / "LICENSE.txt").read_text(encoding="utf-8")
        if (source_url not in readme or launcher_url not in readme
                or "elisa/h/huffbench.elisa" not in readme
                or "zig/h/huffbench.zig" not in readme
                or "No rights reserved. This is public domain software, for use by anyone." not in license_text
                or "Scott Robert Ladd" not in license_text):
            raise ValueError("huffbench README or public-domain attribution is incomplete")
        fixtures = {case["id"]: case for case in cases}
        for case_id, passes in (("one_round", 1), ("two_rounds", 2),
                                ("pinned_launcher_round_count", HUFFBENCH_MAX_PASSES),
                                ("exact_capacity", HUFFBENCH_MAX_PASSES)):
            fixture = fixtures[case_id]
            expected_result, expected = expected_output(passes, encoding)
            if (fixture.get("input_value") != passes
                    or fixture.get("expected_result") != expected_result
                    or fixture.get("expected_output", "").encode("ascii") != expected):
                raise ValueError(f"huffbench valid fixture {case_id} does not match the independent verifier")
        for case_id, value in (("below_profile", 0),
                               ("above_profile", HUFFBENCH_MAX_PASSES + 1),
                               ("signed_64_minimum", I64_MIN),
                               ("signed_64_maximum", I64_MAX)):
            fixture = fixtures[case_id]
            if (fixture.get("input_value") != value
                    or fixture.get("expected_result") != -1
                    or fixture.get("expected_output") != ""):
                raise ValueError(f"huffbench invalid fixture {case_id} is incorrect")
        if (fixtures["one_byte_short_capacity"].get("input_value") != HUFFBENCH_MAX_PASSES
                or fixtures["one_byte_short_capacity"].get("output_capacity") != HUFFBENCH_MAX_OUTPUT_BYTES - 1
                or fixtures["one_byte_short_capacity"].get("expected_result") != -2
                or fixtures["one_byte_short_capacity"].get("expected_output") != ""
                or fixtures["null_output"].get("input_value") != HUFFBENCH_MIN_PASSES
                or fixtures["null_output"].get("output_capacity") != HUFFBENCH_MAX_OUTPUT_BYTES
                or fixtures["null_output"].get("output_is_null") is not True
                or fixtures["null_output"].get("expected_result") != -2
                or fixtures["exact_capacity"].get("output_capacity") != HUFFBENCH_MAX_OUTPUT_BYTES):
            raise ValueError("huffbench workload is missing its reviewed output-boundary fixtures")

    cases: dict[tuple[int, int, bool], tuple[int, bytes]] = {}

    def add(value: int, capacity: int | None = None,
            capacity_error: int | None = None, output_is_null: bool = False) -> None:
        required_result, required_output = expected_output(value, encoding)
        selected_capacity = (
            MAX_OUTPUT_BYTES if required_result < 0 else required_result
        ) if capacity is None else capacity
        if (type(selected_capacity) is not int
                or not 0 <= selected_capacity <= MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool):
            raise ValueError("generated scalar byte-output call metadata is out of range")
        selected_capacity_error = capacity_error_result if capacity_error is None else capacity_error
        result, output = expected_call(value, encoding, selected_capacity, output_is_null,
                                       workload, selected_capacity_error)
        cases[(value, selected_capacity, output_is_null)] = (result, output)

    for case in workload["cases"]:
        value = case["input_value"]
        required_result, required_output = expected_output(value, encoding)
        output_capacity = case.get("output_capacity", case.get("workspace_bytes",
                                                                len(required_output) or MAX_OUTPUT_BYTES))
        output_is_null = case.get("output_is_null", False)
        if (type(output_capacity) is not int or not 0 <= output_capacity <= MAX_OUTPUT_BYTES
                or type(output_is_null) is not bool):
            raise ValueError(f"invalid output capacity in {case['id']}")
        expected_result, output = expected_call(
            value, encoding, output_capacity, output_is_null, workload,
            case.get("capacity_error_result", capacity_error_result))
        expected_matches = (case.get("expected_output_hex", "").lower() == output.hex()
                            if "expected_output_hex" in case
                            else case.get("expected_output") == output.decode("ascii"))
        if case["expected_result"] != expected_result or not expected_matches:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(value, output_capacity, case.get("capacity_error_result"), output_is_null)

    elif encoding == "evalloop_stdout_ascii":
        for value in (0, 1, 2, 999, EVALLOOP_MAX_PASSES):
            add(value)
        for value in (-1, EVALLOOP_MAX_PASSES + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (1, EVALLOOP_MAX_PASSES):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
            add(value, EVALLOOP_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "mcgill_misr_report_ascii":
        for value in (MCGILL_MISR_MIN_EXPERIMENTS, 2, 10, 100,
                      MCGILL_MISR_MAX_EXPERIMENTS):
            add(value)
        for value in (MCGILL_MISR_MIN_EXPERIMENTS - 1,
                      MCGILL_MISR_MAX_EXPERIMENTS + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (MCGILL_MISR_MIN_EXPERIMENTS, 10,
                      MCGILL_MISR_MAX_EXPERIMENTS):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
            add(value, MCGILL_MISR_MAX_OUTPUT_BYTES)
            add(value, MCGILL_MISR_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "shootout_lists_stdout_ascii":
        for value in (SHOOTOUT_LISTS_MIN_RUNS, 1, 2, SHOOTOUT_LISTS_MAX_RUNS):
            add(value)
        for value in (-1, SHOOTOUT_LISTS_MAX_RUNS + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (1, SHOOTOUT_LISTS_MAX_RUNS):
            add(value, 3)
            add(value, SHOOTOUT_LISTS_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "shootout_strcat_stdout_ascii":
        for value in (SHOOTOUT_STRCAT_MIN_APPEND_COUNT, 1, 5, 6, 10, 11,
                      SHOOTOUT_STRCAT_MAX_APPEND_COUNT):
            add(value)
        for value in (-1, SHOOTOUT_STRCAT_MAX_APPEND_COUNT + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (1, 6, 11, SHOOTOUT_STRCAT_MAX_APPEND_COUNT):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
            add(value, SHOOTOUT_STRCAT_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "shootout_methcall_stdout_ascii":
        for value in (SHOOTOUT_METHCALL_MIN_CALLS, -1, 0, 1, 2, 3, 4, 6,
                      SHOOTOUT_METHCALL_MAX_CALLS):
            add(value)
        for value in (SHOOTOUT_METHCALL_MIN_CALLS - 1,
                      SHOOTOUT_METHCALL_MAX_CALLS + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (3, 6, SHOOTOUT_METHCALL_MAX_CALLS):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
            add(value, SHOOTOUT_METHCALL_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "shootout_objinst_stdout_ascii":
        for value in (SHOOTOUT_OBJINST_MIN_N, -1, 0, 1, 2, SHOOTOUT_OBJINST_MAX_N):
            add(value)
        for value in (SHOOTOUT_OBJINST_MIN_N - 1,
                      SHOOTOUT_OBJINST_MAX_N + 1, I64_MIN, I64_MAX):
            add(value)
        required, _ = expected_output(1, encoding)
        add(1, required - 1)
        add(1, SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES, output_is_null=True)
        add(SHOOTOUT_OBJINST_MIN_N, SHOOTOUT_OBJINST_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "shootout_random_ascii":
        for value in (SHOOTOUT_RANDOM_MIN_CALL_COUNT, 2, 10, 1000,
                      SHOOTOUT_RANDOM_MAX_CALL_COUNT, 0, -1,
                      SHOOTOUT_RANDOM_MAX_CALL_COUNT + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (SHOOTOUT_RANDOM_MIN_CALL_COUNT, 1000, SHOOTOUT_RANDOM_MAX_CALL_COUNT):
            required, _ = expected_output(value, encoding)
            for capacity in sorted({0, max(0, required - 1), required, required + 1}):
                add(value, capacity)
        for value in (SHOOTOUT_RANDOM_MIN_CALL_COUNT, SHOOTOUT_RANDOM_MAX_CALL_COUNT):
            add(value, SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "benchmarkgame_recursive_ascii":
        for value in range(BENCHMARKGAME_RECURSIVE_MIN_N, BENCHMARKGAME_RECURSIVE_MAX_N + 1):
            add(value)
        for value in (-1, BENCHMARKGAME_RECURSIVE_MAX_N + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (BENCHMARKGAME_RECURSIVE_MIN_N, 1):
            required, _ = expected_output(value, encoding)
            for capacity in sorted({0, max(0, required - 1), required, required + 1}):
                add(value, capacity)
        for value in (BENCHMARKGAME_RECURSIVE_MIN_N, BENCHMARKGAME_RECURSIVE_MAX_N):
            add(value, BENCHMARKGAME_RECURSIVE_MAX_OUTPUT_BYTES, output_is_null=True)
    elif encoding == "shootout_ary3_ascii":
        for value in range(1, 33):
            add(value)
        for value in (64, 257, 1024, ARY3_MAX_LENGTH):
            add(value)
        rng_ary3 = random.Random(20261019)
        for _ in range(32):
            add(rng_ary3.randint(1, 128))
        for value in (0, -1, ARY3_MAX_LENGTH + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (1, 10, ARY3_MAX_LENGTH):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
        add(1, 10, output_is_null=True)
    elif encoding == "prime_factorial_unique_u32le":
        # The pinned routine scans every candidate and trial-divides each one;
        # keep this corpus small while still covering the upper bound.
        for value in (2, 3, 4, 12, 30, 210, 2310, 4093, 4096):
            add(value)
        for value, capacity in ((2310, 0), (2310, 4), (2310, 19), (2310, 20),
                                (4096, 3), (4096, 4)):
            add(value, capacity)
    elif encoding == "stream_sieve_primes_i32le":
        for value in range(-4, STREAM_SIEVE_MAX_COUNT + 1):
            add(value)
        for value in (STREAM_SIEVE_MIN_COUNT, STREAM_SIEVE_MIN_COUNT - 1,
                      -1, 0, 1, STREAM_SIEVE_MAX_COUNT, STREAM_SIEVE_MAX_COUNT + 1,
                      I64_MIN, I64_MAX):
            add(value)
        rng_stream_sieve = random.Random(20261016)
        for _ in range(192):
            add(rng_stream_sieve.randint(-128, STREAM_SIEVE_MAX_COUNT))
        for value, capacity in ((1, 0), (1, 3), (1, 4), (1, 5),
                                (10, 39), (10, 40), (10, 41),
                                (STREAM_SIEVE_MAX_COUNT, STREAM_SIEVE_MAX_OUTPUT_BYTES - 1),
                                (STREAM_SIEVE_MAX_COUNT, STREAM_SIEVE_MAX_OUTPUT_BYTES),
                                (STREAM_SIEVE_MAX_COUNT, STREAM_SIEVE_MAX_OUTPUT_BYTES + 1)):
            add(value, capacity)
        for value in (STREAM_SIEVE_MIN_COUNT, -1, 0):
            add(value, 0, output_is_null=True)
        for value in (1, 10, STREAM_SIEVE_MAX_COUNT):
            add(value, STREAM_SIEVE_MAX_OUTPUT_BYTES, output_is_null=True)
        add(STREAM_SIEVE_MIN_COUNT - 1, 0, output_is_null=True)
    elif encoding == "huffbench_summary_ascii":
        for value in (HUFFBENCH_MIN_PASSES, 2, 3, 17, 29, HUFFBENCH_MAX_PASSES,
                      0, -1, HUFFBENCH_MAX_PASSES + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (HUFFBENCH_MIN_PASSES, 2, HUFFBENCH_MAX_PASSES):
            required, _ = expected_output(value, encoding)
            for capacity in sorted({0, required - 1, required,
                                    min(HUFFBENCH_MAX_OUTPUT_BYTES, required + 1)}):
                add(value, capacity)
            add(value, HUFFBENCH_MAX_OUTPUT_BYTES, output_is_null=True)
    else:
        for value in range(4097):
            add(value)
        rng = random.Random(20261014)
        for _ in range(512):
            add(rng.randrange(0, I64_MAX + 1))
        for value in (I64_MIN, I64_MIN + 1, -1024, -2, -1, 0, 1, 2, I64_MAX - 1, I64_MAX):
            add(value)
        capacity_cases = ((0, 1, 7, 33, I64_MAX) if encoding == "pascal_triangle_row"
                          else (0, 1, 7, 90, I64_MAX) if encoding == "floyd_triangle"
                          else (0, 1, 7, 512, I64_MAX) if encoding == "harmonic_series"
                          else (0, 1, 45, 46, I64_MAX) if encoding == "butterfly_pattern"
                          else (0, 1, 7, 45, I64_MAX) if encoding == "magicdiamondpattern"
                          else (0, 1, 7, I64_MAX))
        for value in capacity_cases:
            result, _ = expected_output(value, encoding)
            add(value, max(0, result - 1))

    lines = [f"{len(cases)}\n"]
    for (value, capacity, output_is_null), (result, output) in sorted(cases.items()):
        encoded = output.hex() if output else "-"
        lines.append(f"{value} {result} {capacity} {int(output_is_null)} {len(output)} {encoded}\n")
    return "".join(lines), len(cases)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_scalar_bytes_output")
    checker = manifest["binaries"]["i64_scalar_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"scalar byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_scalar_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    encoding = workload.get("input", {}).get("encoding", workload.get("input", {}).get("radix", 2))
    if algorithm in {"evalloop", "huffbench"}:
        encoding = workload.get("output", {}).get("encoding")
    capacity_error_result = workload.get("output", {}).get(
        "capacity_error_result", workload.get("output", {}).get("insufficient_capacity_result", -2))
    for case, record in zip(workload["cases"], records):
        value = case["input_value"]
        required_result, required_output = expected_output(value, encoding)
        output_capacity = case.get("output_capacity", case.get("workspace_bytes",
                                                                  len(required_output) or MAX_OUTPUT_BYTES))
        output_is_null = case.get("output_is_null", False)
        expected, _ = expected_call(
            value, encoding, output_capacity, output_is_null, workload,
            case.get("capacity_error_result", capacity_error_result))
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] is not None
                or record["workload"]["input_value"] != value
                or record["workload"]["output_capacity"] != output_capacity
                or record["workload"].get("output_is_null", False) != output_is_null
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_scalar_bytes_output")
    args = parser.parse_args()
    if (args.jobs < 1 or len(set(args.languages)) != len(args.languages)
            or len(set(args.algorithms)) != len(args.algorithms)):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {
        algorithm: json.loads((ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                              .read_text(encoding="utf-8"))
        for algorithm in args.algorithms
    }

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm, workload in workloads.items():
            data, case_count = corpus(workload)
            algorithm_directory = directory / algorithm
            algorithm_directory.mkdir(parents=True, exist_ok=True)
            (algorithm_directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      algorithm_directory / language, args.elisa_compiler,
                                      data, case_count, workload)
                jobs[job] = (algorithm, language, case_count)
        for job in as_completed(jobs):
            algorithm, language, case_count = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {case_count} oracle values, "
                  f"{result['workload_records']} workload records", flush=True)
    all_passed = not failures and len(results) == len(args.algorithms) * len(args.languages)
    report = {"algorithms": args.algorithms, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": all_passed,
              "results": sorted(results, key=lambda row: (row["algorithm"], row["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if all_passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
