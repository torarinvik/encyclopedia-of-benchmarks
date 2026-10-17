#!/usr/bin/env python3
"""Check Roman numeral decoders against a canonical-form oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import re
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case
from run_i64_scalar_bytes_output import expected_output

ALGORITHM = "roman_to_integer"
MAX_LENGTH = 15
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
WORKLOAD_PATH = ROOT / "benchmarks/r/roman_to_integer/workload.json"
CANONICAL = re.compile(r"M{0,3}(?:CM|CD|D?C{0,3})(?:XC|XL|L?X{0,3})(?:IX|IV|V?I{0,3})\Z")
VALUES = {ord("I"): 1, ord("V"): 5, ord("X"): 10, ord("L"): 50,
          ord("C"): 100, ord("D"): 500, ord("M"): 1000}


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_LENGTH
            or any(type(value) is not int or value not in VALUES for value in values)):
        return -1
    text = "".join(chr(value) for value in values)
    if not CANONICAL.fullmatch(text) or not text:
        return -1
    result = 0
    for index, value in enumerate(values):
        if index + 1 < len(values) and VALUES[value] < VALUES[values[index + 1]]:
            result -= VALUES[value]
        else:
            result += VALUES[value]
    return result if 1 <= result <= 3999 else -1


def corpus(workload: dict) -> tuple[str, int]:
    cases = {tuple(encode_case(case, algorithm=ALGORITHM)): case["expected_result"] for case in workload["cases"]}
    for case in workload["cases"]:
        if oracle(case["input_values"]) != case["expected_result"]:
            raise ValueError(f"published workload disagrees with canonical Roman oracle: {case['id']}")
    for number in range(1, 4000):
        _, roman = expected_output(number, "roman")
        values = list(roman)
        cases[tuple(values)] = number
    symbols = tuple(map(ord, "IVXLCDMA"))
    for length in range(5):
        for sequence in product(symbols, repeat=length):
            values = list(sequence)
            cases[tuple(values)] = oracle(values)
    boundaries = [-1, 0, 73, 86, 88, 76, 67, 68, 77, 97, 128, I64_MIN, I64_MAX]
    cases.update({(value,): oracle([value]) for value in boundaries})
    cases.update({(left, right): oracle([left, right]) for left in boundaries for right in boundaries})
    cases[(77,) * 16] = -1
    rng = random.Random(20261014)
    choices = list(map(ord, "IVXLCDMivxlcdmA?0")) + [-1, 128, I64_MAX]
    for _ in range(512):
        values = [rng.choice(choices) for _ in range(rng.randrange(0, 19))]
        cases[tuple(values)] = oracle(values)
    lines = [str(len(cases)) + "\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


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
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/roman_to_integer")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "roman_to_integer-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
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
