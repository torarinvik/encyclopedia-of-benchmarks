#!/usr/bin/env python3
"""Check binomial-coefficient ports against Python's arbitrary-precision math.comb."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_binary_scalar import encode_values

ALGORITHM = "binomial_coefficient"
U64_MAX = 2**64 - 1


def oracle(n: int, k: int) -> int:
    if type(n) is not int or type(k) is not int or not 0 <= n <= U64_MAX or not 0 <= k <= U64_MAX:
        raise ValueError("binomial inputs must be unsigned 64-bit integers")
    if n > 66:
        return -1
    if k > n:
        return 0
    from math import comb
    return comb(n, k)


def corpus(workload: dict) -> tuple[str, int]:
    pairs = {(n, k) for n in range(67) for k in range(67)}
    edge_values = [0, 1, 2, 65, 66, 67, 68, U64_MAX - 1, U64_MAX]
    pairs.update((n, k) for n in edge_values for k in edge_values)
    pairs.update((n, k) for n, k in ((66, 0), (66, 1), (66, 32), (66, 33), (66, 34),
                                     (66, 65), (66, 66), (67, 0), (67, U64_MAX),
                                     (U64_MAX, 0), (0, U64_MAX)))
    rng = random.Random(20261014)
    pairs.update((rng.getrandbits(64), rng.getrandbits(64)) for _ in range(512))
    for case in workload["cases"]:
        n, k, expected = encode_values(case)
        if expected != oracle(n, k):
            raise ValueError(f"published workload disagrees with math.comb: {case['id']}")
        pairs.add((n, k))
    data = "".join(f"{n} {k} {oracle(n, k)}\n" for n, k in sorted(pairs))
    return data, len(pairs)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="binary_scalar")
    checker = manifest["binaries"]["binary_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"binary scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_binary_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(records_path)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        n, k, expected = encode_values(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [n, k]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/binomial_coefficient")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/b/binomial_coefficient/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle pairs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": {"os": platform.system(), "architecture": platform.machine()},
              "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
              "corpus_path": str(corpus_path),
              "all_passed": not failures and len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
