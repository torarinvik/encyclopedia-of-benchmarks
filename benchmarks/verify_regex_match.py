#!/usr/bin/env python3
"""Verify the recursive regex ports against an independent dynamic-programming oracle."""

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

ALGORITHM = "regex_match"
MAX_TEXT_LENGTH = 12
MAX_PATTERN_LENGTH = 20


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int for value in values)):
        return -1
    text_length, pattern_length = values[:2]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or not 0 <= pattern_length <= MAX_PATTERN_LENGTH:
        return -1
    if len(values) != 2 + text_length + pattern_length:
        return -1
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if any(not 97 <= symbol <= 122 for symbol in text):
        return -1
    for index, symbol in enumerate(pattern):
        if not (97 <= symbol <= 122 or symbol in (ord("."), ord("*"))):
            return -1
        if symbol == ord("*") and (index == 0 or pattern[index - 1] == ord("*")):
            return -1

    table = [[False] * (pattern_length + 1) for _ in range(text_length + 1)]
    table[0][0] = True
    for column in range(2, pattern_length + 1):
        if pattern[column - 1] == ord("*"):
            table[0][column] = table[0][column - 2]
    for row in range(1, text_length + 1):
        for column in range(1, pattern_length + 1):
            token = pattern[column - 1]
            if token == ord(".") or token == text[row - 1]:
                table[row][column] = table[row - 1][column - 1]
            elif token == ord("*"):
                atom = pattern[column - 2]
                table[row][column] = table[row][column - 2] or (
                    (atom == ord(".") or atom == text[row - 1])
                    and table[row - 1][column]
                )
    return int(table[text_length][pattern_length])


def packed(text: str, pattern: str) -> tuple[int, ...]:
    if len(text) > MAX_TEXT_LENGTH or len(pattern) > MAX_PATTERN_LENGTH:
        raise ValueError("corpus inputs exceed the benchmark bounds")
    return (len(text), len(pattern), *(ord(char) for char in text),
            *(ord(char) for char in pattern))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = tuple(encode_case(case))
        expected = case["expected_result"]
        if oracle(list(values)) != expected:
            raise ValueError(f"published workload disagrees with the DP oracle: {case['id']}")
        cases[values] = expected

    texts = ["".join(chars) for length in range(5) for chars in product("ab", repeat=length)]
    token_choices = [atom + suffix for atom in "ab." for suffix in ("", "*")]
    patterns = [""]
    for token_count in range(1, 5):
        patterns.extend("".join(tokens) for tokens in product(token_choices, repeat=token_count))
    for text in texts:
        for pattern in patterns:
            values = packed(text, pattern)
            cases[values] = oracle(list(values))

    invalid_inputs = [
        (), (1,), (-1, 0), (13, 0), (0, 21), (1, 0), (0, 1),
        (1, 0, 65), (0, 1, 63), (0, 1, 42), (0, 3, 97, 42, 42),
        (1, 1, 97, 97, 97),
    ]
    for values in invalid_inputs:
        cases[values] = -1

    boundary_pairs = [
        ("", ""), ("a" * 12, "a" * 12), ("abcdefghijkl", "." * 12),
        ("a" * 12, "a*" * 10), ("a" * 12, "a*" * 9 + "b"),
    ]
    for text, pattern in boundary_pairs:
        values = packed(text, pattern)
        cases[values] = oracle(list(values))

    rng = random.Random(20261014)
    for _ in range(256):
        text = "".join(rng.choice("abc") for _ in range(rng.randrange(MAX_TEXT_LENGTH + 1)))
        token_count = rng.randrange(11)
        pattern = "".join(rng.choice("ab.") + ("*" if rng.randrange(2) else "")
                           for _ in range(token_count))
        if len(pattern) > MAX_PATTERN_LENGTH:
            pattern = pattern[:MAX_PATTERN_LENGTH]
            if pattern.endswith("*") and (len(pattern) == 1 or pattern[-2] == "*"):
                pattern = pattern[:-1]
        values = packed(text, pattern)
        cases[values] = oracle(list(values))

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
        raise RuntimeError(f"array-scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of result records")
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
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/r/regex_match/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "regex_match-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
