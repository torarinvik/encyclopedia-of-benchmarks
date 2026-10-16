#!/usr/bin/env python3
"""Verify both A1Z26 directions against their shared byte-level contracts."""

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

ALGORITHMS = ("a1z26_cipher", "a1z26_decipher")
FAMILY = "i64_array_bytes_output"


def corpus(workload: dict, algorithm: str) -> tuple[str, int]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
    default_capacity = workload.get("workspace", {}).get("bytes")

    def add(values: tuple[int, ...], capacity: int | None = None) -> None:
        result, output = expected_output(list(values), algorithm)
        selected_capacity = capacity
        if selected_capacity is None:
            selected_capacity = len(output) if default_capacity is None else default_capacity
        if result >= 0 and selected_capacity < len(output):
            result, output = -2, b""
        cases[(values, selected_capacity)] = (result, output)

    if algorithm == "a1z26_cipher":
        for value in range(128):
            add((value,))
        alphabet = (0, 49, 65, 90, 97, 122, 127)
    else:
        for value in range(-1, 29):
            add((value,))
        alphabet = (0, 1, 13, 26, 27, 28)
    for first, second in product(alphabet, repeat=2):
        add((first, second))

    rng = random.Random(20261014)
    for _ in range(512):
        length = rng.randrange(67)
        if algorithm == "a1z26_cipher":
            values = tuple(rng.choice((rng.randrange(65, 91), rng.randrange(97, 123),
                                       rng.randrange(128))) for _ in range(length))
        else:
            values = tuple(rng.randrange(-1, 29) for _ in range(length))
        add(values)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = expected_output(list(values), algorithm)
        capacity = case.get("workspace_bytes", default_capacity)
        expected_result = (case.get("capacity_error_result", -2)
                           if capacity is not None and result >= 0 and capacity < len(output) else result)
        expected_output = b"" if capacity is not None and result >= 0 and capacity < len(output) else output
        if (case["expected_result"] != expected_result
                or case["expected_output_hex"] != expected_output.hex()):
            raise ValueError(f"workload oracle mismatch for {algorithm}: {case['id']}")
        add(values, capacity)

    add((65,) if algorithm == "a1z26_cipher" else (1,), capacity=0)
    lines = [f"{len(cases)}\n"]
    for (values, capacity), (result, output) in sorted(cases.items()):
        encoded = output.hex() if output else "-"
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)} {capacity}{values_text} {encoded}\n")
    return "".join(lines), len(cases)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
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
        result, output = expected_output(values, algorithm)
        capacity = case.get(
            "workspace_bytes",
            workload.get("workspace", {}).get("bytes", len(output)),
        )
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["output_capacity"] != capacity
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/a1z26")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)

    workloads = {}
    corpora = {}
    for algorithm in ALGORITHMS:
        workload = json.loads((ROOT / "benchmarks/a" / algorithm / "workload.json").read_text(encoding="utf-8"))
        workloads[algorithm] = workload
        data, count = corpus(workload, algorithm)
        corpora[algorithm] = (data, count)
        (directory / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in ALGORITHMS:
            data, count = corpora[algorithm]
            workload = workloads[algorithm]
            for language in args.languages:
                target = directory / algorithm / language
                job = executor.submit(verify, algorithm, language, target,
                                      args.elisa_compiler, data, count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((algorithm, language, str(error)))
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)

    report = {"algorithms": list(ALGORITHMS), "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"])),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
