#!/usr/bin/env python3
"""Check two-input scalar ports through their C ABI and workload recorder."""

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

U64_MAX = 2**64 - 1
I64_MAX = 2**63 - 1
ALGORITHMS = ("hamming_distance", "gcd", "lcm")


def oracle(left: int, right: int) -> int:
    if type(left) is not int or type(right) is not int or not 0 <= left <= U64_MAX or not 0 <= right <= U64_MAX:
        raise ValueError("inputs must be unsigned 64-bit integers")
    return format(left ^ right, "064b").count("1")


def gcd_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= I64_MAX or not 0 <= right <= I64_MAX):
        raise ValueError("gcd inputs must be nonnegative signed 64-bit integers")
    if left == 0:
        return right
    if right == 0:
        return left
    common_shifts = 0
    while (left & 1) == 0 and (right & 1) == 0:
        left >>= 1
        right >>= 1
        common_shifts += 1
    while (left & 1) == 0:
        left >>= 1
    while right != 0:
        while (right & 1) == 0:
            right >>= 1
        if left > right:
            left, right = right, left
        right -= left
    return left << common_shifts


def lcm_oracle(left: int, right: int) -> int:
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= I64_MAX or not 0 <= right <= I64_MAX):
        raise ValueError("lcm inputs must be nonnegative signed 64-bit integers")
    if left == 0 or right == 0:
        return 0
    value = (left // gcd_oracle(left, right)) * right
    return value if value <= I64_MAX else -1


def result(algorithm: str, left: int, right: int) -> int:
    if algorithm == "hamming_distance":
        return oracle(left, right)
    if algorithm == "gcd":
        return gcd_oracle(left, right)
    if algorithm == "lcm":
        return lcm_oracle(left, right)
    raise ValueError(f"no independent oracle for {algorithm}")


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    pairs = {tuple(case["input_values"]) for case in workload["cases"]}
    pairs.update((left, right) for left in range(256) for right in range(256))
    if algorithm == "hamming_distance":
        edge_values = [0, 1, 2**63, U64_MAX, 0xAAAAAAAAAAAAAAAA, 0x5555555555555555]
        random_bits = 64
    else:
        edge_values = [0, 1, 2, 3, I64_MAX, I64_MAX - 1, 7540113804746346429, 4660046610375530309]
        random_bits = 63
    pairs.update((left, right) for left in edge_values for right in edge_values)
    rng = random.Random(20261014)
    pairs.update((rng.getrandbits(random_bits), rng.getrandbits(random_bits)) for _ in range(512))
    for case in workload["cases"]:
        left, right, expected = encode_values(case)
        if expected != result(algorithm, left, right):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
    data = "".join(f"{left} {right} {result(algorithm, left, right)}\n" for left, right in sorted(pairs))
    return data, len(pairs)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="binary_scalar")
    checker = manifest["binaries"]["binary_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=90)
    if checked.returncode:
        raise RuntimeError(f"binary C ABI correctness check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_binary_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=90)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        left, right, expected = encode_values(case)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [left, right]
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/binary_scalar")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages) or len(set(args.algorithms)) != len(args.algorithms):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workloads = {}
    corpora = {}
    corpus_paths = {}
    for algorithm in args.algorithms:
        workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
        workloads[algorithm] = json.loads(workload_path.read_text(encoding="utf-8"))
        corpora[algorithm] = corpus(algorithm, workloads[algorithm])
        corpus_paths[algorithm] = directory / f"{algorithm}-corpus.txt"
        corpus_paths[algorithm].write_text(corpora[algorithm][0], encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {}
        for algorithm in args.algorithms:
            data, case_count = corpora[algorithm]
            workload = workloads[algorithm]
            for language in args.languages:
                job = executor.submit(verify, algorithm, language,
                                      directory / algorithm[0] / algorithm / language,
                                      args.elisa_compiler, data, case_count, workload)
                jobs[job] = (algorithm, language)
        for job in as_completed(jobs):
            algorithm, language = jobs[job]
            try:
                result = job.result()
                print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle pairs, "
                      f"{result['workload_records']} workload records", flush=True)
            except Exception as error:
                result = {"algorithm": algorithm, "language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "algorithms": args.algorithms, "languages": args.languages,
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": all(result["status"] == "passed" for result in results),
              "corpora": {algorithm: {"path": str(corpus_paths[algorithm]),
                                      "sha256": hashlib.sha256(corpora[algorithm][0].encode()).hexdigest()}
                          for algorithm in args.algorithms},
              "verification_source_sha256": sha256_file(Path(__file__)),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_binary_scalar.py"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "workloads": {algorithm: sha256_file(ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json")
                            for algorithm in args.algorithms},
              "results": sorted(results, key=lambda result: (result["algorithm"], result["language"]))}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
