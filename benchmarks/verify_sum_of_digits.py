#!/usr/bin/env python3
"""Check the iterative sum-of-digits ports against a decimal-string oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import json
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_scalar import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "sum_of_digits"
I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def oracle(value: int) -> int:
    if not I32_MIN <= value <= I32_MAX:
        return -1
    return sum(int(digit) for digit in str(abs(value)))


def corpus() -> tuple[str, dict]:
    workload = json.loads((ROOT / "benchmarks/s/sum_of_digits/workload.json")
                          .read_text(encoding="utf-8"))
    inputs = {case["input_value"] for case in workload["cases"]}
    inputs.update(range(-10000, 10001))
    inputs.update([I32_MIN - 1, I32_MIN, I32_MIN + 1, -1000000000, -10, -1,
                   1, 10, 1000000000, I32_MAX - 1, I32_MAX, I32_MAX + 1])
    for power in range(10):
        value = 10**power
        inputs.update((value - 1, value, value + 1, -value - 1, -value, -value + 1))
    rng = random.Random(20261014)
    inputs.update(rng.randrange(I32_MIN - 1, I32_MAX + 2) for _ in range(512))
    for case in workload["cases"]:
        if case["expected_result"] != oracle(case["input_value"]):
            raise ValueError(f"published workload disagrees with decimal-string oracle: {case['id']}")
    data = "".join(f"{value} {oracle(value)}\n" for value in sorted(inputs))
    return data, workload


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True)
    checker = manifest["binaries"]["scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=60)
    if checked.returncode:
        raise RuntimeError(f"scalar C ABI check failed: {checked.stderr}")
    count = json.loads(checked.stdout)["cases_checked"]
    if count != len(data.splitlines()):
        raise RuntimeError("checker did not consume the full oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    command = [sys.executable, str(ROOT / "benchmarks/run_scalar.py"),
               "--algorithm", ALGORITHM, "--language", language,
               "--source", str(ROOT / manifest["source_path"]),
               "--executable", manifest["binaries"]["scalar_runner"]["path"],
               "--compiler", manifest["compiler"], "--compiler-version", manifest["compiler_version"],
               "--build-flags=" + manifest["build_flags"],
               "--build-command", "\n".join(shlex.join(c) for c in manifest["commands"]),
               "--samples", "1", "--warmups", "0", "--repetitions", "1",
               "--output", str(records_path)]
    recorded = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=60)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["workload"]["input_value"] != case["input_value"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["workload"]["input_length"] is not None
                or len(record["measurement"]["samples_ns"]) != 1
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]):
            raise RuntimeError(f"result/provenance mismatch in {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "source_sha256": manifest["source_sha256"], "oracle_cases": count,
            "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
            "workload_cases": len(records), "workload_sha256": sha256_file(
                ROOT / "benchmarks/s/sum_of_digits/workload.json"),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path),
            "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/scalar")
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    directory = args.build_dir.resolve() / "s" / ALGORITHM
    data, workload = corpus()
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {result['oracle_cases']} oracle inputs, "
                  f"{result['workload_cases']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": True,
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
