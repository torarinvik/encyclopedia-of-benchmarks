#!/usr/bin/env python3
"""Check decimal increment ports against an arbitrary-precision oracle."""

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
from run_i64_array_bytes_output import expected_output

ALGORITHM = "plus_one"
FAMILY = "i64_array_bytes_output"
MAX_LENGTH = 256


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (len(values) > MAX_LENGTH
            or any(type(value) is not int or not 0 <= value <= 9 for value in values)
            or (len(values) > 1 and values[0] == 0)):
        return -1, b""
    decimal = "".join(str(value) for value in values) or "0"
    output = str(int(decimal) + 1).encode("ascii")
    return len(output), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int | None = None) -> None:
        result, output = oracle(list(values))
        if (result, output) != expected_output(list(values), ALGORITHM):
            raise ValueError("production workload oracle differs from arbitrary-precision oracle")
        selected_capacity = len(output) if capacity is None else capacity
        if result >= 0 and selected_capacity < len(output):
            result, output = -2, b""
        cases[(values, selected_capacity)] = result, output

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = oracle(list(values))
        if (case["expected_result"] != result
                or case["expected_output_hex"] != output.hex()):
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
        add(values)

    add(())
    for length in range(1, 5):
        for digits in product(range(10), repeat=length):
            if length > 1 and digits[0] == 0:
                continue
            add(digits)

    add((9,) * MAX_LENGTH)
    add((1,) + (0,) * (MAX_LENGTH - 1))
    add((1,) * MAX_LENGTH)
    add((0, 1))
    add((-1, 2))
    add((1, 10))
    add((1,) * (MAX_LENGTH + 1))
    add((9,), capacity=0)
    add((1, 2, 3), capacity=2)

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randrange(MAX_LENGTH + 1)
        digits = [rng.randrange(10) for _ in range(length)]
        if length > 1 and digits[0] == 0:
            digits[0] = rng.randrange(1, 10)
        add(tuple(digits))

    lines = [f"{len(cases)}\n"]
    for (values, _capacity), (result, output) in sorted(cases.items()):
        encoded_values = "" if not values else " " + " ".join(map(str, values))
        encoded_output = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{encoded_values} {encoded_output}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(
        ALGORITHM,
        language,
        directory,
        compiler=elisa_compiler if language == "elisa" else None,
        with_checker=True,
        family=FAMILY,
    )
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [
            sys.executable,
            str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
            "--build-manifest", str(directory / "build.json"),
            "--samples", "1",
            "--warmups", "0",
            "--repetitions", "1",
            "--output", str(output),
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        timeout=120,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")

    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result, expected = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or len(record["measurement"]["samples_ns"]) != 1
                or case["expected_output_hex"] != expected.hex()):
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
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/plus_one")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(
        (ROOT / "benchmarks/p/plus_one/workload.json")
        .read_text(encoding="utf-8")
    )
    data, case_count = corpus(workload)
    (directory / "oracle-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(
                verify,
                language,
                directory / ALGORITHM / language,
                args.elisa_compiler,
                data,
                case_count,
                workload,
            ): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(
                f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                f"{result['workload_records']} workload records",
                flush=True,
            )

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "results": sorted(results, key=lambda item: item["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
