#!/usr/bin/env python3
"""Check signed-integer reversal ports against a string-based oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "reverse_integer"
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
INVALID_RESULT = I32_MIN - 1
WORKLOAD_PATH = ROOT / "benchmarks/r/reverse_integer/workload.json"


def oracle(value: int) -> int:
    if type(value) is not int or not I64_MIN <= value <= I64_MAX:
        raise ValueError("input must be a signed 64-bit integer")
    if not I32_MIN <= value <= I32_MAX:
        return INVALID_RESULT
    sign = -1 if value < 0 else 1
    reversed_value = sign * int(str(abs(value))[::-1])
    return reversed_value if I32_MIN <= reversed_value <= I32_MAX else 0


def corpus(workload: dict) -> tuple[str, int]:
    cases = {value: oracle(value) for value in range(-15_000, 15_001)}
    boundaries = {
        I64_MIN, I64_MIN + 1, I32_MIN - 1, I32_MIN, I32_MIN + 1,
        I32_MAX - 1, I32_MAX, I32_MAX + 1, I64_MAX - 1, I64_MAX,
        -2_147_483_649, 2_147_483_648,
    }
    for power in (10**exponent for exponent in range(10)):
        for value in (power - 1, power, power + 1, -power - 1, -power, -power + 1):
            if I64_MIN <= value <= I64_MAX:
                boundaries.add(value)
    for value in boundaries:
        cases[value] = oracle(value)

    rng = random.Random(20261018)
    for _ in range(40_000):
        value = rng.randint(I32_MIN, I32_MAX)
        cases[value] = oracle(value)

    for case in workload["cases"]:
        value = case["input_value"]
        expected = oracle(value)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with integer oracle: {case['id']}")
        cases[value] = expected
    data = "".join(f"{value} {expected}\n" for value, expected in sorted(cases.items()))
    return data, len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="scalar")
    checker = manifest["binaries"]["scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    command = [sys.executable, str(ROOT / "benchmarks/run_scalar.py"),
               "--algorithm", ALGORITHM, "--language", language,
               "--source", str(ROOT / manifest["source_path"]),
               "--executable", manifest["binaries"]["scalar_runner"]["path"],
               "--compiler", manifest["compiler"], "--compiler-version", manifest["compiler_version"],
               "--build-flags=" + manifest["build_flags"],
               "--build-command", "\n".join(shlex.join(item) for item in manifest["commands"]),
               "--samples", "1", "--warmups", "0", "--repetitions", "1",
               "--output", str(records_path)]
    recorded = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_value"] != case["input_value"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["workload"]["input_length"] is not None
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/reverse_integer")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
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
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
