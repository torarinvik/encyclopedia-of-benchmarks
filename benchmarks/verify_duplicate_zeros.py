#!/usr/bin/env python3
"""Verify fixed-length zero-duplication ports against an independent array oracle."""

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

ALGORITHM = "duplicate_zeros"


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > 64
            or any(type(value) is not int or not 0 <= value <= 1000 for value in values)):
        return -1, b""
    transformed = []
    for value in values:
        if len(transformed) == len(values):
            break
        transformed.append(value)
        if value == 0 and len(transformed) < len(values):
            transformed.append(0)
    output = b"".join(value.to_bytes(4, "little", signed=True) for value in transformed)
    return len(values), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for length in range(7):
        for values in product(range(3), repeat=length):
            cases[values] = oracle(list(values))
    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randrange(0, 65)
        values = tuple(rng.choice([0, 0, 0, 1, 2, 3, 17, 999, 1000])
                       for _index in range(length))
        cases[values] = oracle(list(values))
    for values in ((0,), (1, 0), (0, 1), (1, 2, 0), (0, 0, 0, 0),
                   (0, 1000) * 32, (-1,), (1001,), tuple([1] * 65)):
        cases[values] = oracle(list(values))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result = oracle(list(values))
        if (case["expected_result"] != result[0]
                or case["expected_output_hex"] != result[1].hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        if expected_output(list(values), ALGORITHM) != result:
            raise ValueError(f"recorder oracle differs from verifier oracle: {case['id']}")
        cases[values] = result

    records = sorted(cases.items())
    records.append(((0,), (-2, b"")))  # Valid one-zero input with no output capacity.
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {count} {len(output)}{values_text} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
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
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or case["expected_result"] != result[0]
                or record["workload"]["expected_result"] != result[0]
                or record["measurement"]["observed_result"] != result[0]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/duplicate_zeros")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/d/duplicate_zeros/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                   data, case_count, workload): language for language in args.languages}
        for future in as_completed(futures):
            language = futures[future]
            try:
                result = future.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} output-array cases, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"]),
              "all_passed": not failures and len(results) == len(args.languages)}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
