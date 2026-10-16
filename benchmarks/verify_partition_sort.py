#!/usr/bin/env python3
"""Check partition-sort ports against an exhaustive signed-32-bit corpus."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "partition_sort"
MAX_LENGTH = 6
I32_MIN, I32_MAX = -(2**31), 2**31 - 1


def corpus(workload: dict) -> tuple[str, int]:
    arrays: set[tuple[int, ...]] = set()
    # Four ordered values span every small ordering/duplicate pattern while
    # keeping the exhaustive corpus bounded for this first-pivot quicksort.
    for length in range(MAX_LENGTH + 1):
        arrays.update(itertools.product(range(4), repeat=length))
    arrays.update({
        (I32_MIN,), (I32_MAX,), (I32_MIN, I32_MAX), (I32_MAX, I32_MIN),
        (I32_MIN, 0, I32_MAX), (I32_MAX, I32_MIN, -1, 0, 1),
        (I32_MIN, I32_MIN, I32_MAX, I32_MAX, 0, -1),
        (5, 4, 3, 2, 1, 0), (0, 1, 2, 3, 4, 5), (7, 7, 7, 7, 7, 7),
    })
    rng = random.Random(20261015)
    for _ in range(256):
        length = rng.randrange(MAX_LENGTH + 1)
        arrays.add(tuple(rng.randrange(I32_MIN, I32_MAX + 1) for _ in range(length)))

    ordered = sorted(arrays, key=lambda values: (len(values), values))
    lines = [f"{len(ordered)}\n"]
    lines.extend(f"{len(values)}" + (" " + " ".join(map(str, values)) if values else "") + "\n"
                 for values in ordered)
    return "".join(lines), len(ordered)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="sort")
    checker = manifest["binaries"]["sort_checker"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"C ABI sort check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("sort checker did not consume the full oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_sort.py"),
         "--algorithm", ALGORITHM, "--language", language,
         "--source", str(ROOT / manifest["source_path"]),
         "--executable", manifest["binaries"]["sort_runner"]["path"],
         "--compiler", manifest["compiler"],
         "--compiler-version", manifest["compiler_version"],
         "--build-flags=" + manifest["build_flags"],
         "--build-command", "\n".join(shlex.join(command) for command in manifest["commands"]),
         "--samples", "1", "--warmups", "0", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    lengths = workload["input"]["lengths"]
    if len(records) != len(lengths):
        raise RuntimeError("sort recorder emitted an unexpected number of records")
    for length, record in zip(lengths, records):
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
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/p/partition_sort/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path),
        "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/sort/p/partition_sort")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload_path = ROOT / "benchmarks/p/partition_sort/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("measurement", {}).get("comparison_model") != "sort_call"
            or workload.get("input", {}).get("lengths") != [0, 16, 256, 1024]):
        parser.error("partition_sort workload does not match the reviewed sort contract")
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
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
