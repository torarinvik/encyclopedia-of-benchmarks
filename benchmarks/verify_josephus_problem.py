#!/usr/bin/env python3
"""Verify three Josephus strategies against a recurrence oracle in every target language."""

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
from run_i64_array_scalar import encode_case

ALGORITHMS = ("josephus_problem", "josephus_problem_recursive", "josephus_problem_simulation")
MAXIMUM = {"josephus_problem": 100000,
           "josephus_problem_recursive": 256,
           "josephus_problem_simulation": 512}
I64_MAX = 2**63 - 1


def oracle(values: list[int], algorithm: str) -> int:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value <= I64_MAX for value in values)):
        return -1
    participants, step = values
    if not 1 <= participants <= MAXIMUM[algorithm] or not 1 <= step <= I64_MAX:
        return -1
    survivor = 0
    for circle_size in range(1, participants + 1):
        survivor = (survivor + step % circle_size) % circle_size
    return survivor + 1


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case, algorithm=algorithm)
        expected = oracle(values, algorithm)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {algorithm}/{case['id']}")
        cases[tuple(values)] = expected
    limit = min(MAXIMUM[algorithm], 80)
    for participants in range(1, limit + 1):
        for step in range(1, 2 * participants + 4):
            values = [participants, step]
            cases[tuple(values)] = oracle(values, algorithm)
    for participants in {1, 2, MAXIMUM[algorithm]}:
        for step in {1, 2, 3, participants, participants + 1, I64_MAX - 1, I64_MAX}:
            values = [participants, step]
            cases[tuple(values)] = oracle(values, algorithm)
    rng = random.Random(20261014)
    for _ in range(256):
        participants = rng.randint(1, MAXIMUM[algorithm])
        step = rng.choice([1, 2, 3, participants, participants + 1,
                           I64_MAX - 1, I64_MAX, rng.randint(1, I64_MAX)])
        values = [participants, step]
        cases[tuple(values)] = oracle(values, algorithm)
    for values in [(), (0, 1), (-1, 3), (5, 0), (5, -1), (I64_MAX, 1)]:
        cases[values] = oracle(list(values), algorithm)
    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(algorithm: str, language: str, directory: Path,
           elisa_compiler: str | None, data: str, count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    completed = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if completed.returncode:
        raise RuntimeError(f"oracle check failed: {completed.stderr}")
    if json.loads(completed.stdout)["cases_checked"] != count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": count, "workload_records": len(records),
            "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/josephus_problem")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.algorithms)) != len(args.algorithms) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and algorithm/language selections must be unique")
    workloads = {name: json.loads((ROOT / "benchmarks/j" / name / "workload.json").read_text(encoding="utf-8"))
                 for name in args.algorithms}
    corpora = {name: corpus(name, workloads[name]) for name in args.algorithms}
    build_dir = args.build_dir.resolve()
    build_dir.mkdir(parents=True, exist_ok=True)
    for name, (data, _) in corpora.items():
        (build_dir / f"{name}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, name, language, build_dir / name / language,
                                args.elisa_compiler, *corpora[name], workloads[name]): (name, language)
                for name in args.algorithms for language in args.languages}
        for job in as_completed(jobs):
            name, language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {name}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {name}/{language}: {result['oracle_cases']} oracle cases, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithms": args.algorithms,
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"]))}
    report_path = build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
