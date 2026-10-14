#!/usr/bin/env python3
"""Verify Tower of Hanoi move streams against recursion and legal-state replay."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output, fnv1a

ALGORITHM = "tower_of_hanoi"


def encode(values: list[int], count: int, output: bytes) -> str:
    values_text = "" if not values else " " + " ".join(map(str, values))
    encoded = output.hex() if output else "-"
    return f"{len(values)} {count} {len(output)}{values_text} {encoded}\n"


def validate_move_stream(values: list[int], output: bytes) -> None:
    disks, source, destination, auxiliary = values
    stacks = [[], [], []]
    stacks[source] = list(range(disks, 0, -1))
    for offset in range(0, len(output), 2):
        origin, target = output[offset], output[offset + 1]
        if origin == target or not stacks[origin]:
            raise ValueError(f"illegal move in output for {values}")
        disk = stacks[origin].pop()
        if stacks[target] and stacks[target][-1] < disk:
            raise ValueError(f"larger disk placed on smaller disk for {values}")
        stacks[target].append(disk)
    if stacks[destination] != list(range(disks, 0, -1)):
        raise ValueError(f"disks did not finish on the destination peg for {values}")
    if any(stacks[peg] for peg in range(3) if peg != destination):
        raise ValueError(f"non-destination peg was not empty for {values}")


def corpus(workload: dict) -> tuple[str, int]:
    records: list[tuple[list[int], int, bytes]] = []
    for case in workload["cases"]:
        values = case["input_values"]
        count, output = expected_output(values, ALGORITHM)
        if case["expected_result"] != count or case["expected_order"] != list(output):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        if count >= 0:
            validate_move_stream(values, output)
        records.append((values, count, output))

    for disks in range(13):
        for pegs in itertools.permutations(range(3)):
            values = [disks, *pegs]
            count, output = expected_output(values, ALGORITHM)
            if count != (1 << disks) - 1:
                raise ValueError(f"recurrence returned the wrong move count: {values}")
            validate_move_stream(values, output)
            records.append((values, count, output))

    malformed = [
        [],
        [0],
        [0, 0, 1],
        [0, 0, 0, 1],
        [0, -1, 1, 2],
        [0, 0, 1, 3],
        [13, 0, 1, 2],
    ]
    for values in malformed:
        records.append((values, *expected_output(values, ALGORITHM)))

    # A valid sequence needs more than zero bytes; ensure no partial output is written.
    records.append(([4, 0, 2, 1], -2, b""))

    lines = [f"{len(records)}\n"]
    lines.extend(encode(values, count, output) for values, count, output in records)
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"move-stream C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full move corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    output_records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(output_records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected record count")
    for case, record in zip(workload["cases"], output_records):
        values = case["input_values"]
        expected_count, expected_bytes = expected_output(values, ALGORITHM)
        if expected_count >= 0:
            validate_move_stream(values, expected_bytes)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_count
                or record["measurement"]["observed_result"] != expected_count
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)
                or case["expected_order"] != list(expected_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded move/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(output_records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/tower_of_hanoi")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload_path = ROOT / "benchmarks/t/tower_of_hanoi/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "tower_of_hanoi-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} move cases, "
                      f"{result['workload_records']} workload records", flush=True)
            results.append(result)

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(args.languages)
                      and all(result["status"] == "passed" for result in results),
        "corpus_sha256": sha256_file(corpus_path),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "workload_sha256": sha256_file(workload_path),
        "results": sorted(results, key=lambda item: item["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
