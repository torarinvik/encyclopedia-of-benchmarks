#!/usr/bin/env python3
"""Verify portable AsconDigest ports against source vectors and byte messages."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from ascon_digest_oracle import expected_output
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "ascon_digest"
WORKLOAD_PATH = ROOT / "benchmarks/a/ascon_digest/workload.json"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def include(values: tuple[int, ...]) -> None:
        cases[values] = expected_output(list(values))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = expected_output(list(values))
        if (case["expected_result"] != result
                or case["expected_output_hex"] != output.hex()):
            raise ValueError(f"workload disagrees with source-vector oracle: {case['id']}")
        include(values)

    for variant in (0, 1):
        for length in range(0, 130):
            include((variant, length, *((index * 37 + length * 11) & 255
                                        for index in range(length))))
        include((variant, 4096, *((index * 73 + 19) & 255 for index in range(4096))))

    rng = random.Random(20261015)
    for _ in range(128):
        variant = rng.randrange(2)
        length = rng.choice((rng.randrange(0, 1025), 4095, 4096))
        include((variant, length, *(rng.randrange(256) for _ in range(length))))

    for values in ((), (0,), (-1, 0), (2, 0), (0, -1), (0, 4097),
                   (0, 1), (0, 1, -1), (0, 1, 256), (1, 0, 0),
                   (1, 2, 1), (1, 0, 7)):
        include(values)

    records = [(values, result) for values, result in sorted(cases.items())]
    # A valid hash call with no output workspace must fail without writing.
    records.append(((0, 0), (-2, b"")))
    lines = [f"{len(records)}\n"]
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
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=240)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=240)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected_count, expected_bytes = expected_output(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_count
                or record["measurement"]["observed_result"] != expected_count
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
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
        "recorder_output": str(output_path),
        "recorder_output_sha256": sha256_file(output_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output/ascon_digest")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages):
        parser.error("jobs must be between 1 and the selected language count")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language,
                            args.build_dir / language,
                            args.elisa_compiler, data, case_count, workload): language
            for language in args.languages
        }
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda record: record["language"])
    report = {
        "schema_version": 1,
        "algorithm": ALGORITHM,
        "status": "passed",
        "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "platform": {"system": platform.system(), "release": platform.release(),
                     "machine": platform.machine(), "python": platform.python_version()},
        "oracle_cases_per_language": case_count,
        "workload_records_per_language": len(workload["cases"]),
        "languages": results,
    }
    path = args.build_dir / "verification.json"
    path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "oracle_cases_per_language": case_count,
                      "languages": [record["language"] for record in results],
                      "report": str(path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
