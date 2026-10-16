#!/usr/bin/env python3
"""Verify Bitap string matcher ports against an independent substring oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "bitap_string_match"
WORKLOAD_PATH = ROOT / "benchmarks/b/bitap_string_match/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: tuple[int, ...] | list[int]) -> int:
    """Decode the packed input and find the first match with a naive scan."""
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -2
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= 4096 or not 0 <= pattern_length <= 63
            or len(values) != 2 + text_length + pattern_length):
        return -2
    text_values = values[2:2 + text_length]
    pattern_values = values[2 + text_length:]
    if any(not 97 <= byte <= 122 for byte in (*text_values, *pattern_values)):
        return -2
    if pattern_length == 0:
        return 0
    if pattern_length > text_length:
        return -1
    final_start = text_length - pattern_length
    for start in range(final_start + 1):
        if text_values[start:start + pattern_length] == pattern_values:
            return start
    return -1


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def include(values: tuple[int, ...] | list[int]) -> None:
        packed = tuple(values)
        expected = oracle(packed)
        if all(I64_MIN <= value <= I64_MAX for value in packed) and len(packed) <= 100001:
            runner_case = {"input_values": list(packed), "expected_result": expected}
            if encode_case(runner_case, ALGORITHM) != list(packed):
                raise ValueError("array-scalar recorder changed the packed input")
        cases[packed] = expected

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = oracle(values)
        if case.get("expected_result") != expected:
            raise ValueError(f"published workload disagrees with independent oracle: {case['id']}")
        encode_case(case, ALGORITHM)
        include(values)

    alphabet = (97, 98)
    for text_length in range(7):
        for text in product(alphabet, repeat=text_length):
            for pattern_length in range(6):
                for pattern in product(alphabet, repeat=pattern_length):
                    include((text_length, pattern_length, *text, *pattern))

    rng = random.Random(20261015)
    for _ in range(512):
        text = tuple(rng.randrange(97, 123) for _ in range(rng.randrange(65)))
        pattern_length = rng.randrange(65)
        if text and pattern_length <= len(text) and rng.randrange(2):
            start = rng.randrange(len(text) - pattern_length + 1)
            pattern = text[start:start + pattern_length]
        else:
            pattern = tuple(rng.randrange(97, 123) for _ in range(pattern_length))
        include((len(text), len(pattern), *text, *pattern))

    invalid_inputs = [
        (), (0,), (-1, 0), (0, -1), (4097, 0), (0, 64),
        (1, 1), (0, 0, 97), (1, 0, 97), (0, 1), (1, 1, 65, 97),
        (1, 1, -1, 97), (1, 1, 97, 256), (I64_MIN, 0), (I64_MAX, 0),
        (1, 64, *([97] * 65)),
    ]
    for values in invalid_inputs:
        include(values)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"C ABI oracle check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("array-scalar checker did not consume the full corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_scalar/bitap_string_match")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                      f"{result['workload_records']} workload records", flush=True)
            results.append(result)

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(args.languages)
                      and all(result["status"] == "passed" for result in results),
        "corpus_sha256": sha256_file(corpus_path),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda result: result["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
