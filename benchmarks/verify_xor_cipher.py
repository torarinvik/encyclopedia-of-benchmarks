#!/usr/bin/env python3
"""Verify XOR cipher ports against an independent repeating-key byte oracle."""

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

ALGORITHM = "xor_cipher"
FAMILY = "i64_array_bytes_output"


def pack(message: tuple[int, ...], key: tuple[int, ...]) -> tuple[int, ...]:
    return (len(message), len(key), *message, *key)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], capacity: int | None = None) -> None:
        result, output = expected_output(list(values), ALGORITHM)
        selected_capacity = len(output) if capacity is None else capacity
        if result >= 0 and selected_capacity < len(output):
            result, output = -2, b""
        cases[(values, selected_capacity)] = (result, output)

    for message_byte in range(256):
        for key_byte in (0, 1, 17, 128, 255):
            add(pack((message_byte,), (key_byte,)))

    alphabet = (0, 1, 65, 128, 255)
    keys = ((0,), (1,), (255,), (0, 255), (65, 90))
    for message_length in range(4):
        for message in product(alphabet, repeat=message_length):
            for key in keys:
                add(pack(tuple(message), key))

    rng = random.Random(20261014)
    for _ in range(512):
        key = tuple(rng.randrange(256) for _ in range(rng.randrange(1, 17)))
        message_limit = 64 - len(key)
        message = tuple(rng.randrange(256) for _ in range(rng.randrange(message_limit + 1)))
        add(pack(message, key))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = expected_output(list(values), ALGORITHM)
        if (case["expected_result"] != result
                or case["expected_output_hex"] != output.hex()):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)

    for invalid in (
        (), (0, 0), (0, 1), (1, 0, 65), (1, 1), (1, 2, 65, 66),
        (64, 1, 65), (0, 64, *([65] * 64)),
        (1, 1, 256, 0), (1, 1, -1, 0),
    ):
        add(tuple(invalid))
    # A valid one-byte message with no output capacity.
    add(pack((65,), (1,)), capacity=0)

    lines = [f"{len(cases)}\n"]
    for (values, _capacity), (result, output) in sorted(cases.items()):
        encoded = output.hex() if output else "-"
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family=FAMILY)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result, _ = expected_output(values, ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/xor_cipher")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/x/xor_cipher/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "xor_cipher-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
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

    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
