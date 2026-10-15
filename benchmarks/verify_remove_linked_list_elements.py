#!/usr/bin/env python3
"""Check recursive linked-list removal ports against a stable value oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "remove_linked_list_elements"
MAX_NODES = 1024
MIN_I32, MAX_I32 = -(2**31), 2**31 - 1
WORKLOAD_PATH = ROOT / "benchmarks/r/remove_linked_list_elements/workload.json"


def oracle(values: tuple[int, ...]) -> tuple[int, bytes]:
    if (not 1 <= len(values) <= MAX_NODES + 1
            or any(type(value) is not int or not MIN_I32 <= value <= MAX_I32
                   for value in values)):
        return -1, b""
    target, *nodes = values
    survivors = [value for value in nodes if value != target]
    output = struct.pack("<" + "i" * len(survivors), *survivors) if survivors else b""
    return len(survivors), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = oracle(values)

    alphabet = (-2, -1, 0, 1, 2)
    for target in alphabet:
        for length in range(6):
            for nodes in product(alphabet, repeat=length):
                add((target, *nodes))

    rng = random.Random(20261018)
    pool = (MIN_I32, MIN_I32 + 1, -1000, -1, 0, 1, 1000, MAX_I32 - 1, MAX_I32)
    for _ in range(768):
        target = rng.choice(pool)
        length = rng.randrange(MAX_NODES + 1)
        add((target, *(rng.choice(pool) for _ in range(length))))

    add((0, *range(MAX_NODES)))
    add((7, *(7 for _ in range(MAX_NODES))))
    add((7, *(0 for _ in range(MAX_NODES))))
    add((MIN_I32, *(MIN_I32 if index % 2 == 0 else MAX_I32 for index in range(MAX_NODES))))
    for invalid in (
        (), (MIN_I32 - 1,), (MAX_I32 + 1,), (0, MIN_I32 - 1),
        (0, MAX_I32 + 1), (0, *(0 for _ in range(MAX_NODES + 1))),
    ):
        add(invalid)
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, _output = oracle(values)
        if result != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        add(values)

    records = sorted(cases.items())
    # Reuse the same input with zero output capacity to verify -2/no-write semantics.
    records.append(((1, 2), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
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
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        result, _output = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != list(values)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/remove_linked_list_elements")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
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
