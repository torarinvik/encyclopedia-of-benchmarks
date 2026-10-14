#!/usr/bin/env python3
"""Check first-tie and signed-tie absolute extrema against exact integer oracles."""
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
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHMS = ("abs_min", "abs_max", "absolute_min", "absolute_max")
MAX_VALUES = 256
MAX_INPUT_VALUES = MAX_VALUES + 1
VALUE_LIMIT = 1_000_000_000_000
SIGNED_TIE_VALUE_LIMIT = 1_000_000_000


def oracle(values: list[int] | tuple[int, ...], *, choose_max: bool,
           signed_ties: bool = False) -> int:
    if not 2 <= len(values) <= MAX_INPUT_VALUES:
        return -1
    count = values[0]
    if not 1 <= count <= MAX_VALUES or len(values) != count + 1:
        return -1
    candidates = values[1:]
    value_limit = SIGNED_TIE_VALUE_LIMIT if signed_ties else VALUE_LIMIT
    if any(not -value_limit <= value <= value_limit for value in candidates):
        return -1
    best = candidates[0]
    for candidate in candidates[1:]:
        magnitude_better = (abs(candidate) > abs(best)) if choose_max else (abs(candidate) < abs(best))
        signed_tie_better = (candidate > best) if choose_max else (candidate < best)
        if magnitude_better or (signed_ties and abs(candidate) == abs(best) and signed_tie_better):
            best = candidate
    return best


def corpus(workload: dict, *, choose_max: bool,
           signed_ties: bool = False) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    value_limit = SIGNED_TIE_VALUE_LIMIT if signed_ties else VALUE_LIMIT

    def include(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(packed, choose_max=choose_max, signed_ties=signed_ties)

    alphabet = (-4, -2, -1, 0, 1, 2, 4)
    for length in range(1, 5):
        for sequence in itertools.product(alphabet, repeat=length):
            include((length, *sequence))
    edges = (-value_limit, -value_limit + 1, -1, 0, 1, value_limit - 1, value_limit)
    for left, right in itertools.product(edges, repeat=2):
        include((2, left, right))

    rng = random.Random(20261014)
    for _ in range(768):
        count = rng.randrange(1, MAX_VALUES + 1)
        include((count, *(rng.randrange(-value_limit, value_limit + 1) for _ in range(count))))
    include((MAX_VALUES, *(index - MAX_VALUES // 2 for index in range(MAX_VALUES))))

    malformed = [
        (), (-1,), (0,), (MAX_VALUES + 1, *(0 for _ in range(MAX_VALUES + 1))),
        (1,), (2, 1), (1, value_limit + 1), (1, -value_limit - 1),
        (1, 0, 0), (2, 0, 1, 2),
    ]
    for values in malformed:
        include(values)
    for _ in range(512):
        size = rng.randrange(0, 65)
        include(tuple(rng.choice((-1, 0, 1, 2, MAX_VALUES, MAX_VALUES + 1,
                                  value_limit + 1, -value_limit - 1))
                      for _ in range(size)))

    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values, choose_max=choose_max, signed_ties=signed_ties)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        include(values)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path,
           elisa_compiler: str | None, data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array-scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result or provenance mismatch: {case['id']}")
    letter = algorithm[0]
    return {
        "algorithm": algorithm,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / f"benchmarks/{letter}/{algorithm}/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path),
        "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithms", nargs="+", choices=ALGORITHMS, default=list(ALGORITHMS))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/a/abs_extrema")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.algorithms)) != len(args.algorithms) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and algorithm/language choices must be unique")

    jobs_to_run = []
    inputs = {}
    for algorithm in args.algorithms:
        workload = json.loads((ROOT / f"benchmarks/a/{algorithm}/workload.json").read_text(encoding="utf-8"))
        data, count = corpus(workload,
                             choose_max=algorithm in ("abs_max", "absolute_max"),
                             signed_ties=algorithm in ("absolute_min", "absolute_max"))
        inputs[algorithm] = (workload, data, count)
        for language in args.languages:
            jobs_to_run.append((algorithm, language, workload, data, count))

    results: list[dict] = []
    failures: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        pending = {pool.submit(verify, algorithm, language,
                               args.build_dir.resolve() / algorithm / language,
                               args.elisa_compiler, data, count, workload): (algorithm, language)
                   for algorithm, language, workload, data, count in jobs_to_run}
        for job in as_completed(pending):
            algorithm, language = pending[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({"algorithm": algorithm, "language": language, "error": str(exc)})
                print(f"FAIL {algorithm}/{language}: {exc}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {algorithm}/{language}: {result['oracle_cases']} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)

    report = {"algorithms": list(args.algorithms), "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures and len(results) == len(jobs_to_run),
              "results": sorted(results, key=lambda item: (item["algorithm"], item["language"])),
              "failures": failures}
    args.build_dir.resolve().mkdir(parents=True, exist_ok=True)
    (args.build_dir.resolve() / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {args.build_dir.resolve() / 'verification.json'}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
