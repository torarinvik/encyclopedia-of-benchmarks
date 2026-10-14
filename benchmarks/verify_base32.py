#!/usr/bin/env python3
"""Verify Base32 byte encoding and decoding across all target languages."""

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
from run_i64_array_bytes_output import expected_output, fnv1a

ALGORITHM = "base32"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        expected = expected_output(values, ALGORITHM)
        if case["expected_result"] != expected[0]:
            raise ValueError(f"workload result mismatch: {case['id']}")
        if expected[0] >= 0:
            if values[0] == 0 and case.get("expected_output", "").encode("ascii") != expected[1]:
                raise ValueError(f"workload encoded bytes mismatch: {case['id']}")
            if values[0] == 1 and case.get("expected_output_hex") != expected[1].hex():
                raise ValueError(f"workload decoded bytes mismatch: {case['id']}")
        cases[tuple(values)] = expected

    for byte in range(256):
        cases[(0, byte)] = expected_output([0, byte], ALGORITHM)
        encoded = expected_output([0, byte], ALGORITHM)[1]
        cases[(1, *encoded)] = (1, bytes([byte]))
    for first in range(256):
        for second in range(256):
            encoded = expected_output([0, first, second], ALGORITHM)[1]
            cases[(0, first, second)] = (8, encoded)
            cases[(1, *encoded)] = (2, bytes([first, second]))

    rng = random.Random(20261014)
    for _ in range(2048):
        payload = bytes(rng.randrange(256) for _ in range(rng.randrange(0, 66)))
        cases[(0, *payload)] = expected_output([0, *payload], ALGORITHM)
        encoded = expected_output([0, *payload], ALGORITHM)[1]
        if len(encoded) <= 65:
            cases[(1, *encoded)] = (len(payload), payload)
        unpadded = encoded.rstrip(b"=")
        if len(unpadded) <= 65:
            cases[(1, *unpadded)] = (len(payload), payload)

    invalid = (
        (2,), (0, -1), (0, 256), (1, 65), (1, 48), (1, 97),
        (1, 77, 90, 61, 61, 61, 61, 61, 61),  # nonzero unused trailing bits
        (1, 77, 89, 61, 61),  # too few padding characters
        (1, 77, 89, 61, 61, 61, 61, 61, 61, 61),  # too much padding
        (1, 77, 61, 65, 61, 61, 61, 61, 61),  # data after padding
        (1, 65, 65, 65), (1, 65, 65, 65, 65, 65),  # invalid symbol counts
    )
    for values in invalid:
        cases[values] = expected_output(list(values), ALGORITHM)
    # Capacity is supplied separately through the output buffer length.
    cases[(0, 1)] = (-2, b"")
    cases[(1, 77, 89, 61, 61, 61, 61, 61, 61)] = (-2, b"")

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {count} {len(output)}{suffix} {output.hex() if output else '-'}\n")
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
        expected_count, expected_bytes = expected_output(values, ALGORITHM)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output/base32")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    root = args.build_dir.resolve()
    root.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/b/base32/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (root / "base32-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, root / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = root / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
