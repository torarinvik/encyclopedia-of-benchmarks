#!/usr/bin/env python3
"""Verify all Knuth-Morris-Pratt ports against Python's independent byte search."""

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

ALGORITHM = "knuth_morris_pratt"
MAX_LENGTH = 4096
WORKLOAD_PATH = ROOT / "benchmarks/k/knuth_morris_pratt/workload.json"


def oracle(values: list[int]) -> int:
    if not isinstance(values, list) or len(values) < 2 or len(values) > 2 + 2 * MAX_LENGTH:
        return -1
    text_length, pattern_length = values[0], values[1]
    if (type(text_length) is not int or type(pattern_length) is not int
            or not 0 <= text_length <= MAX_LENGTH or not 0 <= pattern_length <= MAX_LENGTH
            or len(values) != 2 + text_length + pattern_length
            or any(type(value) is not int or not 0 <= value <= 127 for value in values[2:])):
        return -1
    text = bytes(values[2:2 + text_length])
    pattern = bytes(values[2 + text_length:])
    return text.find(pattern)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with byte-search oracle: {case['id']}")
        cases[tuple(values)] = expected

    small_strings = [bytes(items) for length in range(6) for items in product((0, 1), repeat=length)]
    for text in small_strings:
        for pattern in small_strings:
            values = [len(text), len(pattern), *text, *pattern]
            cases[tuple(values)] = oracle(values)

    malformed = [
        [], [0], [0, 0, 65], [-1, 0], [MAX_LENGTH + 1, 0], [0, -1],
        [0, 1, 128], [1, 0, -1], [1, 1, 97],
        [MAX_LENGTH + 1, 0, *([97] * (MAX_LENGTH + 1))],
    ]
    for values in malformed:
        cases[tuple(values)] = oracle(values)

    rng = random.Random(20261015)
    alphabet = [0, 1, 65, 97, 98, 127]
    for _ in range(512):
        text = [rng.choice(alphabet) for _ in range(rng.randrange(0, 257))]
        pattern = [rng.choice(alphabet) for _ in range(rng.randrange(0, 65))]
        values = [len(text), len(pattern), *text, *pattern]
        cases[tuple(values)] = oracle(values)

    for text_length, pattern_length, text_byte, pattern_byte in [
        (MAX_LENGTH, 1, 97, 98), (MAX_LENGTH, 2048, 97, 98),
        (257, 129, 0, 127),
    ]:
        text = [text_byte] * text_length
        pattern = [text_byte] * (pattern_length - 1) + [pattern_byte]
        values = [text_length, pattern_length, *text, *pattern]
        cases[tuple(values)] = oracle(values)

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/knuth_morris_pratt")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "knuth_morris_pratt-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
