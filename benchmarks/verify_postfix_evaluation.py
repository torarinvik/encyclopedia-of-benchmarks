#!/usr/bin/env python3
"""Check integer postfix evaluators against an arbitrary-precision oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "postfix_evaluation"
INVALID = -1_000_000_001
MAX_TOKENS = 256
MAX_OPERAND = 1_000_000
MAX_RESULT = 1_000_000_000


def oracle(values: list[int]) -> int:
    if len(values) < 2 or len(values) > 2 * MAX_TOKENS or len(values) % 2:
        return INVALID
    stack: list[int] = []
    for index in range(0, len(values), 2):
        opcode, payload = values[index:index + 2]
        if opcode == 0:
            if not -MAX_OPERAND <= payload <= MAX_OPERAND:
                return INVALID
            stack.append(payload)
            continue
        if opcode not in (1, 2, 3, 4) or payload != 0 or len(stack) < 2:
            return INVALID
        right, left = stack.pop(), stack.pop()
        if opcode == 1:
            result = left + right
        elif opcode == 2:
            result = left - right
        elif opcode == 3:
            result = left * right
        else:
            if right == 0:
                return INVALID
            quotient = abs(left) // abs(right)
            result = -quotient if (left < 0) != (right < 0) else quotient
        if not -MAX_RESULT <= result <= MAX_RESULT:
            return INVALID
        stack.append(result)
    return stack[0] if len(stack) == 1 else INVALID


def checker_corpus(cases: dict[tuple[int, ...], int]) -> str:
    lines = [f"{len(cases)}\n"]
    for values in sorted(cases):
        expected = oracle(list(values))
        serialized = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{serialized}\n")
    return "".join(lines)


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

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(records_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        expected = oracle(values)
        if (expected != case["expected_result"]
                or record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_scalar/p/postfix_evaluation")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/p/postfix_evaluation/workload.json")
                          .read_text(encoding="utf-8"))
    cases: dict[tuple[int, ...], int] = {}
    tokens = ((0, -2), (0, 0), (0, 2), (1, 0), (2, 0), (3, 0), (4, 0))
    for token_count in range(1, 6):
        for sequence in itertools.product(tokens, repeat=token_count):
            values = tuple(value for token in sequence for value in token)
            cases[values] = oracle(list(values))

    rng = random.Random(20261014)
    for _ in range(512):
        depth = 0
        sequence: list[tuple[int, int]] = []
        max_depth = rng.randrange(1, 8)

        def expression(level: int) -> None:
            nonlocal depth
            if level >= max_depth or (level > 0 and rng.random() < 0.35):
                sequence.append((0, rng.randrange(-100, 101)))
                depth += 1
                return
            expression(level + 1)
            expression(level + 1)
            sequence.append((rng.randrange(1, 5), 0))
            depth -= 1

        expression(0)
        values = tuple(value for token in sequence for value in token)
        cases[values] = oracle(list(values))
    for _ in range(512):
        length = rng.randrange(0, 41)
        values = tuple(rng.choice((-2, -1, 0, 1, 2, 3, 4, 5, 1000001))
                       for _ in range(length))
        cases[values] = oracle(list(values))
    # A maximum-size valid postfix sum exercises the fixed stack boundary.
    longest = [(0, 1)]
    for _ in range(MAX_TOKENS // 2 - 1):
        longest.extend(((0, 1), (1, 0)))
    values = tuple(value for token in longest for value in token)
    cases[values] = oracle(list(values))
    for case in workload["cases"]:
        values = tuple(encode_case(case))
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            parser.error(f"workload oracle mismatch: {case['id']}")
        cases[values] = expected

    data = checker_corpus(cases)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, len(cases), workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {language}: {len(cases)} oracle inputs, {result['workload_records']} workload records",
                  flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "oracle_cases": len(cases), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
