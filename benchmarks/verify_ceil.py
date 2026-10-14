#!/usr/bin/env python3
"""Check exact rational ceiling batches against Python integer arithmetic."""
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

ALGORITHM = "ceil"
MAX_VALUES = 256
MAX_INPUT_VALUES = 1 + 2 * MAX_VALUES
NUMERATOR_LIMIT = 1_000_000_000_000
DENOMINATOR_LIMIT = 1_000_000
RESULT_OFFSET = 1_000_000_000_001


def encode_values(fractions: list[tuple[int, int]]) -> list[int]:
    return [len(fractions), *(value for fraction in fractions for value in fraction)]


def oracle(values: list[int]) -> int:
    if len(values) < 1 or len(values) > MAX_INPUT_VALUES:
        return -1
    count = values[0]
    if count < 0 or count > MAX_VALUES or len(values) != 1 + 2 * count:
        return -1
    fractions = [values[index:index + 2] for index in range(1, len(values), 2)]
    for numerator, denominator in fractions:
        if numerator < -NUMERATOR_LIMIT or numerator > NUMERATOR_LIMIT:
            return -1
        if denominator < 1 or denominator > DENOMINATOR_LIMIT:
            return -1
    checksum = 0
    for index, (numerator, denominator) in enumerate(fractions):
        if numerator >= 0:
            result = (numerator + denominator - 1) // denominator
        else:
            result = -(abs(numerator) // denominator)
        checksum += (index + 1) * (result + RESULT_OFFSET)
    return checksum


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def include(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))

    # Exhaust signed numerators and positive denominators in a compact exact domain.
    for numerator in range(-32, 33):
        for denominator in range(1, 9):
            include(encode_values([(numerator, denominator)]))
    for batch in itertools.product(((-7, 3), (-1, 2), (0, 7), (1, 2), (7, 3)), repeat=3):
        include(encode_values(list(batch)))

    rng = random.Random(20261014)
    for _ in range(768):
        count = rng.randrange(MAX_VALUES + 1)
        fractions = [(rng.randrange(-NUMERATOR_LIMIT, NUMERATOR_LIMIT + 1),
                      rng.randrange(1, DENOMINATOR_LIMIT + 1)) for _ in range(count)]
        include(encode_values(fractions))

    include(encode_values([(-NUMERATOR_LIMIT, 1), (-NUMERATOR_LIMIT, DENOMINATOR_LIMIT),
                           (NUMERATOR_LIMIT, 1), (NUMERATOR_LIMIT, DENOMINATOR_LIMIT),
                           (0, 1), (-1, 1), (1, 1)]))
    include(encode_values([(i - 128, (i % 17) + 1) for i in range(MAX_VALUES)]))

    malformed = [
        (), (-1,), (MAX_VALUES + 1,), (1,), (1, 1), (1, 0, 0, 0),
        (1, NUMERATOR_LIMIT + 1, 1), (1, -NUMERATOR_LIMIT - 1, 1),
        (1, 1, 0), (1, 1, DENOMINATOR_LIMIT + 1), (1, 1, -1),
        (2, 1, 1), (0, 1), tuple([MAX_VALUES + 1] + [0] * (2 * MAX_VALUES + 2)),
    ]
    for values in malformed:
        include(values)
    for _ in range(512):
        size = rng.randrange(0, 65)
        include(tuple(rng.choice((-1, 0, 1, 2, MAX_VALUES, MAX_VALUES + 1,
                                  NUMERATOR_LIMIT + 1, DENOMINATOR_LIMIT + 1))
                      for _ in range(size)))

    for case in workload["cases"]:
        values = encode_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        include(values)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
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
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result or provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/c/ceil/workload.json"),
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/c/ceil")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload = json.loads((ROOT / "benchmarks/c/ceil/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    results: list[dict] = []
    failures: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {pool.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({"language": language, "error": str(exc)})
                print(f"FAIL {language}: {exc}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {language}: {case_count} oracle inputs, {result['workload_records']} workload cases",
                  flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "oracle_cases": case_count, "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
