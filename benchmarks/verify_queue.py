#!/usr/bin/env python3
"""Check queue operation traces against an independent FIFO oracle."""

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

ALGORITHM = "queue"
INVALID = -1
CAPACITY = 256
MAX_OPERATIONS = 512


def oracle(values: list[int]) -> int:
    if len(values) > 2 * MAX_OPERATIONS or len(values) % 2:
        return INVALID
    queue: list[int] = []
    checksum = 0
    operation_count = len(values) // 2
    for operation in range(operation_count):
        opcode, payload = values[2 * operation:2 * operation + 2]
        if opcode == 0:
            if not -1_000_000 <= payload <= 1_000_000 or len(queue) == CAPACITY:
                return INVALID
            queue.append(payload)
            continue
        if payload != 0:
            return INVALID
        if opcode == 1:
            if not queue:
                return INVALID
            observed = queue.pop(0)
        elif opcode == 2:
            if not queue:
                return INVALID
            observed = queue[0]
        elif opcode == 3:
            if not queue:
                return INVALID
            observed = queue[-1]
        elif opcode == 4:
            observed = int(not queue)
        elif opcode == 5:
            observed = len(queue)
        else:
            return INVALID
        checksum += (operation + 1) * (observed + 1_000_000)
    for index, value in enumerate(queue):
        checksum += (operation_count + index + 1) * (value + 1_000_000)
    return checksum


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
        values = encode_case(case, ALGORITHM)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/q/queue")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/q/queue/workload.json").read_text(encoding="utf-8"))
    cases: dict[tuple[int, ...], int] = {}
    token_types = ((0, -1), (0, 0), (0, 1), (1, 0), (2, 0), (3, 0), (4, 0), (5, 0))
    for operation_count in range(6):
        for sequence in itertools.product(token_types, repeat=operation_count):
            values = tuple(value for pair in sequence for value in pair)
            cases[values] = oracle(list(values))

    rng = random.Random(20261014)
    for _ in range(768):
        operation_count = rng.randrange(0, MAX_OPERATIONS + 1)
        queue_depth = 0
        values: list[int] = []
        for _step in range(operation_count):
            choices = [4, 5]
            if queue_depth < CAPACITY:
                choices.append(0)
            if queue_depth:
                choices.extend((1, 2, 3))
            opcode = rng.choice(choices)
            if opcode == 0:
                values.extend((0, rng.randrange(-1_000_000, 1_000_001)))
                queue_depth += 1
            else:
                values.extend((opcode, 0))
                if opcode == 1:
                    queue_depth -= 1
        packed = tuple(values)
        cases[packed] = oracle(list(packed))
    for _ in range(512):
        length = rng.randrange(0, 65)
        values = tuple(rng.choice((-1, 0, 1, 2, 3, 4, 5, 6, 1_000_001)) for _ in range(length))
        cases[values] = oracle(list(values))

    full = [value for item in range(CAPACITY) for value in (0, item)]
    cases[tuple(full)] = oracle(full)
    for case in workload["cases"]:
        values = tuple(encode_case(case, ALGORITHM))
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
                failures.append({"language": language, "error": str(error)})
                print(f"FAIL {language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {language}: {len(cases)} oracle traces, {result['workload_records']} workload records",
                  flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "oracle_cases": len(cases), "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
