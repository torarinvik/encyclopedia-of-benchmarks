#!/usr/bin/env python3
"""Check extended-Euclid ports against a recursive Bezout-identity oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "extended_euclidean_algorithm"
I32_MAX = 2**31 - 1


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (len(values) != 2 or any(type(value) is not int or not 1 <= value <= I32_MAX
                                for value in values)):
        return -1, b""

    def recursive(a: int, b: int) -> tuple[int, int, int]:
        if b == 0:
            return a, 1, 0
        gcd, x1, y1 = recursive(b, a % b)
        return gcd, y1, x1 - (a // b) * y1

    result = recursive(*values)
    if result[0] != math.gcd(*values) or values[0] * result[1] + values[1] * result[2] != result[0]:
        raise AssertionError("recursive oracle violated the Bezout identity")
    if any(not -(2**31) <= coefficient <= I32_MAX for coefficient in result):
        raise AssertionError("signed-32-bit result bound violated")
    return 3, struct.pack("<iii", *result)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for a in range(1, 33):
        for b in range(1, 33):
            cases[(a, b)] = oracle([a, b])
    boundaries = [1, 2, 3, 46, 101, 65535, 2147483629, I32_MAX]
    for a in boundaries:
        for b in boundaries:
            cases[(a, b)] = oracle([a, b])
    invalid = [(), (1,), (1, 2, 3), (0, 1), (1, 0), (-1, 5), (5, -1),
               (I32_MAX + 1, 3), (3, I32_MAX + 1), (-(2**63), 1)]
    for values in invalid:
        cases[values] = oracle(list(values))
    rng = random.Random(20261015)
    for _ in range(1024):
        values = (rng.randint(1, I32_MAX), rng.randint(1, I32_MAX))
        cases[values] = oracle(list(values))
    workload_cases = json.loads((ROOT / "benchmarks/e/extended_euclidean_algorithm/workload.json")
                                .read_text(encoding="utf-8"))["cases"]
    for case in workload_cases:
        values = tuple(case["input_values"])
        expected = oracle(list(values))
        if (case["expected_result"] != expected[0]
                or case["expected_output_hex"] != expected[1].hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        cases[values] = expected
    records = sorted(cases.items())
    records.append(((240, 46), (-2, b"")))  # Valid result with zero available capacity.
    lines = [str(len(records)) + "\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {count} {len(output)}{values_text} {output.hex() if output else '-'}\n")
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
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        count, encoded = oracle(case["input_values"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(case["input_values"])
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["expected_result"] != count
                or record["measurement"]["observed_result"] != count
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/extended_euclidean_algorithm")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/e/extended_euclidean_algorithm/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "extended-euclidean-corpus.txt").write_text(data, encoding="utf-8")
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
