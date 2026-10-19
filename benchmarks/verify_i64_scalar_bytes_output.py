#!/usr/bin/env python3
"""Verify scalar-to-byte-buffer ports against independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_scalar_bytes_output import MAX_OUTPUT_BYTES, expected_output
from ary3_oracle import INVALID_RESULT as ARY3_INVALID_RESULT
from ary3_oracle import MAX_LENGTH as ARY3_MAX_LENGTH
from ary3_oracle import MAX_OUTPUT_BYTES as ARY3_MAX_OUTPUT_BYTES
from ary3_oracle import OUTPUT_ERROR as ARY3_OUTPUT_ERROR
from floatmm_oracle import INVALID_RESULT as FLOATMM_INVALID_RESULT
from floatmm_oracle import MAX_OUTPUT_BYTES as FLOATMM_MAX_OUTPUT_BYTES
from floatmm_oracle import MAX_PASSES as FLOATMM_MAX_PASSES
from floatmm_oracle import OUTPUT_ERROR as FLOATMM_OUTPUT_ERROR
from stanford_intmm_oracle import INVALID_RESULT as STANFORD_INTMM_INVALID_RESULT
from stanford_intmm_oracle import MAX_OUTPUT_BYTES as STANFORD_INTMM_MAX_OUTPUT_BYTES
from stanford_intmm_oracle import MAX_PASSES as STANFORD_INTMM_MAX_PASSES
from stanford_intmm_oracle import OUTPUT_ERROR as STANFORD_INTMM_OUTPUT_ERROR
from stream_sieve_oracle import I32_MIN as STREAM_SIEVE_MIN_COUNT
from stream_sieve_oracle import MAX_COUNT as STREAM_SIEVE_MAX_COUNT
from stream_sieve_oracle import MAX_OUTPUT_BYTES as STREAM_SIEVE_MAX_OUTPUT_BYTES
from shootout_sieve_oracle import INVALID_RESULT as SHOOTOUT_SIEVE_INVALID_RESULT
from shootout_sieve_oracle import MAX_ITERATIONS as SHOOTOUT_SIEVE_MAX_ITERATIONS
from shootout_sieve_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_SIEVE_MAX_OUTPUT_BYTES
from shootout_sieve_oracle import OUTPUT_ERROR as SHOOTOUT_SIEVE_OUTPUT_ERROR
from shootout_sieve_oracle import SIEVE_LIMIT as SHOOTOUT_SIEVE_LIMIT
from shootout_random_oracle import INVALID_RESULT as SHOOTOUT_RANDOM_INVALID_RESULT
from shootout_random_oracle import MAX_CALL_COUNT as SHOOTOUT_RANDOM_MAX_CALL_COUNT
from shootout_random_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_RANDOM_MAX_OUTPUT_BYTES
from shootout_random_oracle import MIN_CALL_COUNT as SHOOTOUT_RANDOM_MIN_CALL_COUNT
from shootout_random_oracle import OUTPUT_ERROR as SHOOTOUT_RANDOM_OUTPUT_ERROR
from shootout_heapsort_oracle import INVALID_RESULT as SHOOTOUT_HEAPSORT_INVALID_RESULT
from shootout_heapsort_oracle import MAX_LENGTH as SHOOTOUT_HEAPSORT_MAX_LENGTH
from shootout_heapsort_oracle import MAX_OUTPUT_BYTES as SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES
from shootout_heapsort_oracle import MIN_LENGTH as SHOOTOUT_HEAPSORT_MIN_LENGTH
from shootout_heapsort_oracle import OUTPUT_ERROR as SHOOTOUT_HEAPSORT_OUTPUT_ERROR
from benchmarkgame_recursive_oracle import INVALID_RESULT as BENCHMARKGAME_RECURSIVE_INVALID_RESULT
from benchmarkgame_recursive_oracle import MAX_N as BENCHMARKGAME_RECURSIVE_MAX_N
from benchmarkgame_recursive_oracle import MAX_OUTPUT_BYTES as BENCHMARKGAME_RECURSIVE_MAX_OUTPUT_BYTES
from benchmarkgame_recursive_oracle import MIN_N as BENCHMARKGAME_RECURSIVE_MIN_N
from benchmarkgame_recursive_oracle import OUTPUT_ERROR as BENCHMARKGAME_RECURSIVE_OUTPUT_ERROR

ALGORITHMS = ("decimal_to_binary", "decimal_to_octal", "decimal_to_hexadecimal", "integer_to_roman",
              "pascal_triangle_row", "floyd_triangle", "harmonic_series", "butterfly_pattern",
              "magicdiamondpattern", "prime_factorial", "stream_sieve", "ary3", "sieve", "floatmm",
              "stanford_intmm", "shootout_random", "shootout_heapsort", "benchmarkgame_recursive")
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


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
    capacity_error_result = workload.get("output", {}).get(
        "capacity_error_result", workload.get("output", {}).get("insufficient_capacity_result", -2))

    if encoding == "stanford_floatmm_diagonal_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/FloatMM.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/info.sh"
        )
        required_case_ids = {
            "zero_passes_empty", "zero_passes_null_output", "one_printed_diagonal",
            "two_printed_diagonals", "all_source_printed_diagonals", "insufficient_capacity",
            "null_output_positive", "negative_passes_invalid", "above_profile_invalid",
            "int64_min_invalid", "int64_max_invalid",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-stanford-floatmm-bounded-diagonal-ascii-v1"
                or workload.get("algorithm") != "floatmm"
                or workload.get("function_symbol") != "floatmm"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Stanford/FloatMM/FloatMM.c",
                    "symbol": "Mm/main",
                    "url": source_url,
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Stanford/FloatMM/info.sh",
                    "bench_name": "FloatMM",
                    "source_files": ["FloatMM.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "stanford_floatmm_diagonal_ascii",
                    "meaning": "Number of leading Mm(run) calls to execute; each call emits the corresponding diagonal result.",
                    "minimum": 0,
                    "maximum": FLOATMM_MAX_PASSES,
                    "invalid_result": FLOATMM_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": 'printf("%f\\n") for each pass\'s binary32 diagonal cell',
                    "definition": "The exact first passes lines from the source main loop, with six fractional digits and one newline per value.",
                    "maximum_output_bytes": FLOATMM_MAX_OUTPUT_BYTES,
                    "invalid_result": FLOATMM_INVALID_RESULT,
                    "null_output_result": FLOATMM_OUTPUT_ERROR,
                    "insufficient_capacity_result": FLOATMM_OUTPUT_ERROR,
                    "zero_byte_output_result": 0,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or workload.get("source_bound") != {
                    "description": "FloatMM resets seed=74755 on every Mm call, initializes two 40x40 binary32 matrices in row-major order with the 16-bit recurrence seed=(seed*1309+13849)&65535 and entry (temp-(temp/120)*120-60)/3, then computes the full product with row, column, and inner loops ascending and a binary32 accumulator. Mm(run) prints only rmr[run+1][run+1] for run<40 using %f and a newline. The launcher main invokes Mm for run=0..4999; the bounded profile accepts passes=0..40 and preserves the source-visible prefix while omitting later silent repeated products.",
                    "matrix_side": 40,
                    "source_launcher_passes": 5000,
                    "printed_passes": 40,
                    "suite_pass_bounds": [0, FLOATMM_MAX_PASSES],
                    "seed": 74755,
                    "random_recurrence": "seed=(seed*1309+13849)&65535",
                    "matrix_initialization_order": ["left row-major", "right row-major"],
                    "matrix_entry": "(temp - (temp/120)*120 - 60) / 3 as binary32, with integer division before float conversion",
                    "product_order": ["row ascending", "column ascending", "inner index ascending"],
                    "accumulator_type": "binary32",
                    "output_order": "rmr[run+1][run+1] for each run from zero to passes-1",
                    "output_format": "printf(\"%f\\n\")",
                }
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("floatmm workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "f" / "floatmm" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("floatmm README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        maximum_case = fixtures["all_source_printed_diagonals"]
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output_positive"]
        zero_null_case = fixtures["zero_passes_null_output"]
        if (maximum_case.get("input_value") != FLOATMM_MAX_PASSES
                or maximum_case.get("expected_result") != len(expected_output(FLOATMM_MAX_PASSES,
                                                                               encoding)[1])
                or capacity_case.get("input_value") != 2
                or capacity_case.get("output_capacity") != len(expected_output(2, encoding)[1]) - 1
                or capacity_case.get("expected_result") != FLOATMM_OUTPUT_ERROR
                or null_case.get("input_value") != 1
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != FLOATMM_OUTPUT_ERROR
                or zero_null_case.get("input_value") != 0
                or zero_null_case.get("output_is_null") is not True
                or zero_null_case.get("expected_result") != 0
                or fixtures["negative_passes_invalid"].get("input_value") != -1
                or fixtures["above_profile_invalid"].get("input_value") != FLOATMM_MAX_PASSES + 1):
            raise ValueError("floatmm workload is missing its reviewed boundary/output fixtures")
    elif encoding == "stanford_intmm_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/IntMM.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/info.sh"
        )
        required_case_ids = {
            "one_pass", "three_passes", "upstream_ten_pass_profile",
            "zero_passes_invalid", "above_profile_invalid", "signed_64_minimum_invalid",
            "signed_64_maximum_invalid", "insufficient_capacity", "null_output",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-stanford-intmm-bounded-decimal-v1"
                or workload.get("algorithm") != "stanford_intmm"
                or workload.get("function_symbol") != "stanford_intmm"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Stanford/IntMM/IntMM.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written algorithm ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Stanford/IntMM/info.sh",
                    "bench_name": "IntMM",
                    "source_files": ["IntMM.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "stanford_intmm_ascii",
                    "meaning": "Number of complete source-equivalent IntMM passes; each pass emits its corresponding diagonal product cell.",
                    "minimum": 1,
                    "maximum": STANFORD_INTMM_MAX_PASSES,
                    "invalid_result": STANFORD_INTMM_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": 'printf("%d\\n"): signed decimal diagonal product cell followed by LF for each pass',
                    "definition": "For pass index r, the line contains the full 40x40 product's element [r][r] in the source's one-based indexing. Every pass regenerates identical A and B matrices because the source resets the seed.",
                    "maximum_output_bytes": STANFORD_INTMM_MAX_OUTPUT_BYTES,
                    "invalid_result": STANFORD_INTMM_INVALID_RESULT,
                    "null_output_result": STANFORD_INTMM_OUTPUT_ERROR,
                    "insufficient_capacity_result": STANFORD_INTMM_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or workload.get("source_bound") != {
                    "description": "The launcher runs main with no options. It invokes Intmm for run indices 0 through 9. Each invocation reseeds to 74755, regenerates two 40x40 signed integer matrices from the 16-bit LCG, computes the full row-major product, and prints the selected diagonal cell as signed decimal plus LF. The bounded contract makes the number of complete source-equivalent passes an input from 1 through 10.",
                    "upstream_default_passes": 10,
                    "rows": 40,
                    "columns": 40,
                    "seed_initial_value": 74755,
                    "lcg_multiplier": 1309,
                    "lcg_increment": 13849,
                    "lcg_mask": 65535,
                    "matrix_value_range": [-60, 59],
                    "profile_minimum_passes": 1,
                    "profile_maximum_passes": STANFORD_INTMM_MAX_PASSES,
                    "upstream_default_stdout": "\n".join(("-6984", "5732", "8656", "-2156", "-3040", "-2684", "-8664", "852", "560", "300")) + "\n",
                    "invalid_source_case": "The suite wrapper returns -1 for pass counts below 1 or above 10; the launcher itself supplies no input and always performs ten passes.",
                }
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("stanford_intmm workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "stanford_intmm" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("stanford_intmm README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        maximum_case = fixtures["upstream_ten_pass_profile"]
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["one_pass"].get("input_value") != 1
                or fixtures["one_pass"].get("expected_result") != len(expected_output(1, encoding)[1])
                or fixtures["three_passes"].get("input_value") != 3
                or fixtures["three_passes"].get("expected_result") != len(expected_output(3, encoding)[1])
                or maximum_case.get("input_value") != STANFORD_INTMM_MAX_PASSES
                or maximum_case.get("expected_result") != len(expected_output(
                    STANFORD_INTMM_MAX_PASSES, encoding)[1])
                or capacity_case.get("input_value") != STANFORD_INTMM_MAX_PASSES
                or capacity_case.get("output_capacity") != 0
                or capacity_case.get("expected_result") != STANFORD_INTMM_OUTPUT_ERROR
                or null_case.get("input_value") != STANFORD_INTMM_MAX_PASSES
                or null_case.get("output_capacity") != STANFORD_INTMM_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != STANFORD_INTMM_OUTPUT_ERROR
                or fixtures["zero_passes_invalid"].get("input_value") != 0
                or fixtures["above_profile_invalid"].get("input_value") != STANFORD_INTMM_MAX_PASSES + 1
                or fixtures["signed_64_minimum_invalid"].get("input_value") != I64_MIN
                or fixtures["signed_64_maximum_invalid"].get("input_value") != I64_MAX):
            raise ValueError("stanford_intmm workload is missing its reviewed boundary/output fixtures")
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
    elif encoding == "shootout_heapsort_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/heapsort.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/info.sh"
        )
        required_case_ids = {
            "minimum_length", "small_length", "medium_length", "maximum_bounded_length",
            "zero_length_invalid", "one_length_invalid", "above_profile_invalid",
            "signed_64_minimum_invalid", "signed_64_maximum_invalid",
            "insufficient_capacity", "null_output",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-heapsort-bounded-maximum-v1"
                or workload.get("algorithm") != "shootout_heapsort"
                or workload.get("function_symbol") != "shootout_heapsort"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/heapsort/heapsort.c",
                    "symbol": "main and heapsort",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written algorithm ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/heapsort/info.sh",
                    "bench_name": "heapsort",
                    "source_files": ["heapsort.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound") != {
                    "description": "The launcher supplies no run options. The source default is 8,000,000 values, reduced to 800,000 with SMALL_PROBLEM_SIZE. The suite bounds the one-based generated-double heapsort to input lengths 2 through 8,192. Each independent suite call resets last to 42, generates N doubles from the source LCG, performs the source heapsort, and prints the sorted maximum as %.6f followed by LF.",
                    "upstream_default_length": 8000000,
                    "small_problem_size_default_length": 800000,
                    "profile_minimum_length": SHOOTOUT_HEAPSORT_MIN_LENGTH,
                    "profile_maximum_length": SHOOTOUT_HEAPSORT_MAX_LENGTH,
                    "lcg_initial_state": 42,
                    "lcg_multiplier": 3877,
                    "lcg_increment": 29573,
                    "lcg_modulus": 139968,
                    "source_output_format": "printf(\"%f\\n\", values[N])",
                    "invalid_source_case": "The source does not define safe behavior for N below 2; the suite returns -1 outside its bounded profile.",
                }
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_heapsort_ascii",
                    "meaning": "Number of generated doubles to heapsort before returning the maximum in source-style decimal ASCII.",
                    "minimum": SHOOTOUT_HEAPSORT_MIN_LENGTH,
                    "maximum": SHOOTOUT_HEAPSORT_MAX_LENGTH,
                    "invalid_result": SHOOTOUT_HEAPSORT_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "Fixed-point decimal with six fractional digits and LF, matching printf(\"%f\\n\").",
                    "definition": "The largest of N values generated from the source LCG and sorted by its one-based max-heapsort is formatted to six fractional digits and followed by LF.",
                    "maximum_output_bytes": SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_HEAPSORT_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_HEAPSORT_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_HEAPSORT_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_HEAPSORT_MIN_LENGTH != 2
                or SHOOTOUT_HEAPSORT_MAX_LENGTH != 8192
                or SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES != 9
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("shootout_heapsort workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "shootout_heapsort" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("shootout_heapsort README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        maximum_case = fixtures["maximum_bounded_length"]
        capacity_case = fixtures["insufficient_capacity"]
        null_case = fixtures["null_output"]
        if (fixtures["minimum_length"].get("input_value") != SHOOTOUT_HEAPSORT_MIN_LENGTH
                or fixtures["minimum_length"].get("expected_result") != len(expected_output(
                    SHOOTOUT_HEAPSORT_MIN_LENGTH, encoding)[1])
                or fixtures["small_length"].get("input_value") != 16
                or fixtures["medium_length"].get("input_value") != 256
                or maximum_case.get("input_value") != SHOOTOUT_HEAPSORT_MAX_LENGTH
                or maximum_case.get("expected_result") != SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES
                or capacity_case.get("input_value") != 16
                or capacity_case.get("output_capacity") != SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES - 1
                or capacity_case.get("expected_result") != SHOOTOUT_HEAPSORT_OUTPUT_ERROR
                or null_case.get("input_value") != 16
                or null_case.get("output_capacity") != SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES
                or null_case.get("output_is_null") is not True
                or null_case.get("expected_result") != SHOOTOUT_HEAPSORT_OUTPUT_ERROR
                or fixtures["zero_length_invalid"].get("input_value") != 0
                or fixtures["one_length_invalid"].get("input_value") != 1
                or fixtures["above_profile_invalid"].get("input_value") != SHOOTOUT_HEAPSORT_MAX_LENGTH + 1
                or fixtures["signed_64_minimum_invalid"].get("input_value") != I64_MIN
                or fixtures["signed_64_maximum_invalid"].get("input_value") != I64_MAX):
            raise ValueError("shootout_heapsort workload is missing its reviewed boundary/output fixtures")
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
    elif encoding == "shootout_sieve_ascii":
        source_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/sieve.c"
        )
        launcher_url = (
            "https://github.com/lac-dcc/Benchmarks/blob/"
            "5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/info.sh"
        )
        required_case_ids = {
            "zero_iterations", "one_iteration", "two_iterations", "ten_iterations",
            "maximum_bounded_iterations", "negative_iterations", "iterations_above_bound",
            "signed_64_minimum", "signed_64_maximum", "insufficient_capacity", "null_output",
        }
        case_ids = [case.get("id") for case in workload.get("cases", [])]
        if (workload.get("schema_version") != 1
                or workload.get("id") != "lac-dcc-shootout-sieve-bounded-ascii-v1"
                or workload.get("algorithm") != "sieve"
                or workload.get("function_symbol") != "sieve"
                or workload.get("pinned_source") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/sieve/sieve.c",
                    "symbol": "main",
                    "url": source_url,
                    "license_note": "The referenced C source has no explicit license notice; these are independently written algorithm ports.",
                }
                or workload.get("pinned_launcher") != {
                    "repository": "lac-dcc/Benchmarks",
                    "commit": "5d7b75df749241efa7a6e6f5be613d3fcc5cce38",
                    "path": "Shootout/sieve/info.sh",
                    "bench_name": "sieve",
                    "source_files": ["sieve.c"],
                    "compile_flags": ["-lm"],
                    "run_options": [],
                }
                or workload.get("source_bound", {}).get("upstream_default_iterations") != 170000
                or workload.get("source_bound", {}).get("small_problem_size_default_iterations") != 17000
                or workload.get("source_bound", {}).get("profile_minimum") != 0
                or workload.get("source_bound", {}).get("profile_maximum") != SHOOTOUT_SIEVE_MAX_ITERATIONS
                or workload.get("source_bound", {}).get("upstream_default_count") != 1028
                or workload.get("source_bound", {}).get("upstream_default_stdout") != "Count: 1028\n"
                or workload.get("input") != {
                    "kind": "signed_64_bit_scalar",
                    "encoding": "shootout_sieve_ascii",
                    "meaning": "Number of complete sieve passes over the inclusive range 2..8192.",
                    "minimum": 0,
                    "maximum": SHOOTOUT_SIEVE_MAX_ITERATIONS,
                    "invalid_result": SHOOTOUT_SIEVE_INVALID_RESULT,
                }
                or workload.get("output") != {
                    "kind": "source_stdout_ascii",
                    "encoding": "printf(\"Count: %d\\n\"): final prime count and newline",
                    "definition": "Zero passes produce Count: 0 followed by a newline. One or more passes produce Count: 1028 followed by a newline, the number of primes in [2,8192].",
                    "maximum_output_bytes": SHOOTOUT_SIEVE_MAX_OUTPUT_BYTES,
                    "invalid_result": SHOOTOUT_SIEVE_INVALID_RESULT,
                    "null_output_result": SHOOTOUT_SIEVE_OUTPUT_ERROR,
                    "insufficient_capacity_result": SHOOTOUT_SIEVE_OUTPUT_ERROR,
                    "errors_write_nothing": True,
                }
                or workload.get("measurement") != {
                    "comparison_model": "i64_scalar_bytes_output_call",
                    "sample_count": 5,
                    "warmup_rounds": 1,
                    "repetitions_per_sample": 1,
                }
                or SHOOTOUT_SIEVE_LIMIT != 8192
                or SHOOTOUT_SIEVE_MAX_ITERATIONS != 64
                or SHOOTOUT_SIEVE_MAX_OUTPUT_BYTES != 12
                or len(case_ids) != len(required_case_ids)
                or len(case_ids) != len(set(case_ids))
                or set(case_ids) != required_case_ids):
            raise ValueError("sieve workload metadata does not match its reviewed contract")
        readme = (ROOT / "benchmarks" / "s" / "sieve" / "README.md").read_text(
            encoding="utf-8")
        if source_url not in readme or launcher_url not in readme:
            raise ValueError("sieve README is missing its pinned source or launcher link")
        fixtures = {case["id"]: case for case in workload["cases"]}
        if (fixtures["zero_iterations"].get("input_value") != 0
                or fixtures["zero_iterations"].get("expected_result") != 9
                or fixtures["one_iteration"].get("input_value") != 1
                or fixtures["one_iteration"].get("expected_result") != 12
                or fixtures["maximum_bounded_iterations"].get("input_value") != SHOOTOUT_SIEVE_MAX_ITERATIONS
                or fixtures["maximum_bounded_iterations"].get("expected_result") != 12
                or fixtures["iterations_above_bound"].get("input_value") != SHOOTOUT_SIEVE_MAX_ITERATIONS + 1
                or fixtures["insufficient_capacity"].get("output_capacity") != 11
                or fixtures["insufficient_capacity"].get("expected_result") != SHOOTOUT_SIEVE_OUTPUT_ERROR
                or fixtures["null_output"].get("output_is_null") is not True
                or fixtures["null_output"].get("expected_result") != SHOOTOUT_SIEVE_OUTPUT_ERROR):
            raise ValueError("sieve workload is missing its reviewed boundary or output-error fixtures")

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

    if encoding == "stanford_floatmm_diagonal_ascii":
        for value in (0, 1, 2, 3, 17, 39, FLOATMM_MAX_PASSES,
                      -1, FLOATMM_MAX_PASSES + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (1, 2, FLOATMM_MAX_PASSES):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
            add(value, required, output_is_null=True)
        add(0, 0, output_is_null=True)
    elif encoding == "stanford_intmm_ascii":
        for value in range(1, STANFORD_INTMM_MAX_PASSES + 1):
            add(value)
        for value in (0, -1, STANFORD_INTMM_MAX_PASSES + 1, I64_MIN, I64_MAX):
            add(value)
        rng_intmm = random.Random(20261019)
        for _ in range(32):
            add(rng_intmm.randint(1, STANFORD_INTMM_MAX_PASSES))
        for value in (1, 3, STANFORD_INTMM_MAX_PASSES):
            required, _ = expected_output(value, encoding)
            add(value, required - 1)
            add(value, STANFORD_INTMM_MAX_OUTPUT_BYTES, output_is_null=True)
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
    elif encoding == "shootout_heapsort_ascii":
        for value in (SHOOTOUT_HEAPSORT_MIN_LENGTH, 3, 16, 256, 1024,
                      SHOOTOUT_HEAPSORT_MAX_LENGTH):
            add(value)
        rng_heapsort = random.Random(20261020)
        for _ in range(32):
            add(rng_heapsort.randint(SHOOTOUT_HEAPSORT_MIN_LENGTH, 512))
        for value in (0, 1, SHOOTOUT_HEAPSORT_MAX_LENGTH + 1, I64_MIN, I64_MAX):
            add(value)
        for value in (SHOOTOUT_HEAPSORT_MIN_LENGTH, 16, SHOOTOUT_HEAPSORT_MAX_LENGTH):
            required, _ = expected_output(value, encoding)
            for capacity in sorted({0, max(0, required - 1), required, required + 1}):
                add(value, capacity)
            add(value, SHOOTOUT_HEAPSORT_MAX_OUTPUT_BYTES, output_is_null=True)
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
    elif encoding == "shootout_sieve_ascii":
        for value in (0, 1, 2, 10, SHOOTOUT_SIEVE_MAX_ITERATIONS,
                      -1, SHOOTOUT_SIEVE_MAX_ITERATIONS + 1, I64_MIN, I64_MAX):
            add(value)
        for value, capacity in ((0, 8), (0, 9), (1, 11), (1, 12),
                                (SHOOTOUT_SIEVE_MAX_ITERATIONS,
                                 SHOOTOUT_SIEVE_MAX_OUTPUT_BYTES - 1),
                                (SHOOTOUT_SIEVE_MAX_ITERATIONS,
                                 SHOOTOUT_SIEVE_MAX_OUTPUT_BYTES)):
            add(value, capacity)
        add(1, SHOOTOUT_SIEVE_MAX_OUTPUT_BYTES, output_is_null=True)
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
