#!/usr/bin/env python3
"""Verify External Quicksort ports through the shared sort_call ABI."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
from pathlib import Path
import platform
import shlex
import subprocess
import sys

from build_abi import EXTENSIONS, OPTIONAL_EXTENSIONS, ROOT, build, sha256_file
from e.external_quicksort.independent_oracle import expected_result as independent_sort
from e.external_quicksort.primary_oracle import expected_result as external_oracle
from e.external_quicksort.verify_workload import verify_workload

ALGORITHM = "external_quicksort"
MAX_LENGTH = 1024
MAX_EXHAUSTIVE_LENGTH = 6
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
LANGUAGES = tuple(EXTENSIONS) + tuple(OPTIONAL_EXTENSIONS)


def corpus(workload: dict) -> tuple[str, int, str]:
    arrays: set[tuple[int, ...]] = set()
    for length in range(MAX_EXHAUSTIVE_LENGTH + 1):
        arrays.update(itertools.product((-1, 0, 1), repeat=length))
    arrays.update(tuple(case["input_values"]) for case in workload.get("cases", []))
    arrays.update({
        (I64_MIN, 0, I64_MAX),
        (I64_MAX, I64_MIN, -1, 0, 1, I64_MAX - 1),
        (I64_MIN, I64_MIN, I64_MAX, I64_MAX, 0, -1),
        tuple(range(MAX_LENGTH)),
        tuple(range(MAX_LENGTH - 1, -1, -1)),
        (7,) * MAX_LENGTH,
        tuple((index % 2) * 2 - 1 for index in range(MAX_LENGTH)),
        tuple((index * 97) % 31 - 15 for index in range(MAX_LENGTH)),
    })
    ordered = sorted(arrays, key=lambda values: (len(values), values))
    lines = [f"{len(ordered)}\n"]
    oracle_rows: list[str] = []
    for values in ordered:
        expected = external_oracle(values)
        if expected != independent_sort(values):
            raise ValueError(f"External Quicksort references disagree for {values!r}")
        lines.append(f"{len(values)}" + (" " + " ".join(map(str, values)) if values else "") + "\n")
        oracle_rows.append(json.dumps([values, expected], separators=(",", ":")))
    data = "".join(lines)
    oracle_digest = hashlib.sha256("\n".join(oracle_rows).encode()).hexdigest()
    return data, len(ordered), oracle_digest


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, oracle_digest: str,
           workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="sort")
    checker = manifest["binaries"]["sort_checker"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"C ABI sort check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("sort checker did not consume the full External Quicksort corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [
            sys.executable,
            str(ROOT / "benchmarks/run_sort.py"),
            "--algorithm", ALGORITHM,
            "--language", language,
            "--source", str(ROOT / manifest["source_path"]),
            "--executable", manifest["binaries"]["sort_runner"]["path"],
            "--compiler", manifest["compiler"],
            "--compiler-version", manifest["compiler_version"],
            "--build-flags=" + manifest["build_flags"],
            "--build-command", "\n".join(shlex.join(command) for command in manifest["commands"]),
            "--samples", "1",
            "--warmups", "0",
            "--output", str(records_path),
        ],
        cwd=ROOT, capture_output=True, text=True, timeout=120,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["input"]["lengths"]):
        raise RuntimeError("sort recorder emitted an unexpected number of records")
    for length, record in zip(workload["input"]["lengths"], records):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != length
                or record["measurement"]["observed_result"] != length
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"sort workload/provenance mismatch at length {length}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "oracle_sha256": oracle_digest,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/e/external_quicksort/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path),
        "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=LANGUAGES, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/sort/e/external_quicksort")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload_path = ROOT / "benchmarks/e/external_quicksort/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    issues = verify_workload(workload)
    if issues:
        parser.error("External Quicksort package is incomplete: " + "; ".join(issues))
    data, case_count, oracle_digest = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, oracle_digest, workload): language
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
                print(f"PASS {ALGORITHM}/{language}: {case_count} arrays and "
                      f"{result['workload_records']} workload lengths", flush=True)
            results.append(result)

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(args.languages)
                      and all(result["status"] == "passed" for result in results),
        "corpus_sha256": sha256_file(corpus_path),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda result: result["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
