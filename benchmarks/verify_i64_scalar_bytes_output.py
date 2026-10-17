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
from stream_sieve_oracle import I32_MIN as STREAM_SIEVE_MIN_COUNT
from stream_sieve_oracle import MAX_COUNT as STREAM_SIEVE_MAX_COUNT
from stream_sieve_oracle import MAX_OUTPUT_BYTES as STREAM_SIEVE_MAX_OUTPUT_BYTES

ALGORITHMS = ("decimal_to_binary", "decimal_to_octal", "decimal_to_hexadecimal", "integer_to_roman",
              "pascal_triangle_row", "floyd_triangle", "harmonic_series", "butterfly_pattern",
              "magicdiamondpattern", "prime_factorial", "stream_sieve")
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

    if encoding == "stream_sieve_primes_i32le":
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

    if encoding == "prime_factorial_unique_u32le":
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
