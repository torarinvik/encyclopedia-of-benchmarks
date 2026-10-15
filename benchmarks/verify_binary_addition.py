#!/usr/bin/env python3
"""Verify binary-addition ports against Python integer arithmetic."""

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

ALGORITHM = "binary_addition"


def pack(first: tuple[int, ...], second: tuple[int, ...]) -> tuple[int, ...]:
    return (len(first), len(second), *first, *second)


def oracle(values: tuple[int, ...]) -> tuple[int, bytes]:
    if len(values) < 2 or len(values) > 4096 or any(type(value) is not int for value in values):
        return -1, b""
    first_length, second_length = values[:2]
    if (not 0 <= first_length <= 2047 or not 0 <= second_length <= 2047
            or len(values) != 2 + first_length + second_length):
        return -1, b""
    first = values[2:2 + first_length]
    second = values[2 + first_length:]
    if any(bit not in (0, 1) for bit in first + second):
        return -1, b""
    first_number = int("".join(map(str, first)) or "0", 2)
    second_number = int("".join(map(str, second)) or "0", 2)
    width = max(first_length, second_length)
    total = first_number + second_number
    output = (format(total, f"0{width}b") if width else "")
    if len(output) > width:
        output = format(total, "b")
    return len(output), output.encode("ascii")


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    bit_strings = [bits for length in range(5) for bits in product((0, 1), repeat=length)]
    for first in bit_strings:
        for second in bit_strings:
            values = pack(first, second)
            cases[values] = oracle(values)
    rng = random.Random(20261015)
    for _ in range(512):
        first = tuple(rng.randrange(2) for _ in range(rng.randrange(0, 257)))
        second = tuple(rng.randrange(2) for _ in range(rng.randrange(0, 257)))
        values = pack(first, second)
        cases[values] = oracle(values)
    for values in ((0,), (0, 0, 1), (1, 1, 2, 0), (1, 1, 0, -1),
                   (2048, 0), (0, 2048), (1, 0, 1, 0)):
        cases[values] = oracle(values)
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected_count, _ = oracle(values)
        if case["expected_result"] != expected_count:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = oracle(values)
    records = sorted(cases.items())
    # The checker uses output length as capacity when no workspace is declared.
    records.append(((1, 1, 1, 1), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        output_hex = output.hex() if output else "-"
        lines.append(f"{len(values)} {count} {len(output)}{values_text} {output_hex}\n")
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
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/b/binary_addition/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
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
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
