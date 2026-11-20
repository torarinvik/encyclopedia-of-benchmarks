#!/usr/bin/env python3
"""Verify bitvector inverted-list ports against an independent ID scan."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from i.inverted_list_bitvector_intersection.independent_oracle import verify_result
from i.inverted_list_bitvector_intersection.primary_oracle import (
    MAX_OUTPUT_BYTES,
    expected_output,
)

ALGORITHM = "inverted_list_bitvector_intersection"
FAMILY = "i64_array_bytes_output"
WORKLOAD = ROOT / "benchmarks/i/inverted_list_bitvector_intersection/workload.json"


def _pack_lists(domain: int, rows: tuple[int, ...]) -> tuple[int, ...]:
    words = (domain + 63) // 64
    packed = [domain, len(rows)]
    for mask in rows:
        for word in range(words):
            value = (mask >> (word * 64)) & ((1 << 64) - 1)
            packed.append(value if value < (1 << 63) else value - (1 << 64))
    return tuple(packed)


def corpus(workload: dict) -> tuple[str, int]:
    records: dict[tuple[tuple[int, ...], bool, int, bool], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...], *, input_is_null: bool = False,
            capacity: int | None = None, output_is_null: bool = False) -> None:
        selected_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
        result, payload = expected_output(
            values, capacity=selected_capacity, output_is_null=output_is_null,
            input_is_null=input_is_null, input_length=len(values),
        )
        if not verify_result(
            values, result, payload, output_capacity=selected_capacity,
            output_is_null=output_is_null, input_is_null=input_is_null,
            input_length=len(values),
        ):
            raise ValueError("independent verifier rejected generated input")
        records[(values, input_is_null, selected_capacity, output_is_null)] = (result, payload)

    # Exhaust every pair of bitmap sets on the smallest domains.
    for domain in range(1, 5):
        for left, right in itertools.product(range(1 << domain), repeat=2):
            add(_pack_lists(domain, (left, right)))

    # Exercise multiword boundaries and varied list counts with fixed input bits.
    rng = random.Random(20261116)
    for domain in (63, 64, 65, 70, 127, 128, 129, 255, 256, 257, 1023, 1024):
        for list_count in (1, 2, 3, 8, 16):
            rows = tuple(rng.getrandbits(domain) for _ in range(list_count))
            add(_pack_lists(domain, rows))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, payload = expected_output(
            values, capacity=case["output_capacity"],
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length", len(values)),
        )
        if (result != case["expected_result"]
                or payload.hex() != case.get("expected_output_hex", "")):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        if not verify_result(
            values, result, payload, output_capacity=case["output_capacity"],
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length", len(values)),
        ):
            raise ValueError(f"independent verifier rejected workload: {case['id']}")
        records[(values, case.get("input_is_null", False), case["output_capacity"],
                 case.get("output_is_null", False))] = (result, payload)

    lines = [f"{len(records)}\n", "bytes_with_capacity\n"]
    for key, (result, payload) in sorted(records.items()):
        values, input_is_null, capacity, output_is_null = key
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = payload.hex() if payload else "-"
        lines.append(
            f"{len(values)} {result} {len(payload)} {capacity} "
            f"{int(input_is_null)} {int(output_is_null)}{values_text} {encoded}\n"
        )
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
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
    measured = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(measured) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], measured):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "workload_records": len(measured), "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output), "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/inverted_list_bitvector_intersection")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                results.append(job.result())
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs", flush=True)
    report = {
        "algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(), "all_passed": not failures,
        "results": sorted(results, key=lambda item: item["language"]), "failures": failures,
    }
    (directory / "verification.json").write_text(json.dumps(report, indent=2) + "\n",
                                                 encoding="utf-8")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
