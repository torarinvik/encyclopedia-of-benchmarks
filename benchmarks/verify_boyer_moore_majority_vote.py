#!/usr/bin/env python3
"""Check majority-vote ports against an independent frequency oracle."""

from __future__ import annotations

import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "boyer_moore_majority_vote"
MAX_LENGTH = 256
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def oracle(values: list[int]) -> int:
    if len(values) < 1 or len(values) > MAX_LENGTH:
        return -1
    counts = Counter(values)
    return next((value for value, count in counts.items() if count > len(values) // 2), -1)


def signed_i64(rng: random.Random) -> int:
    value = rng.getrandbits(64)
    return value if value <= I64_MAX else value - 2**64


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with frequency oracle: {case['id']}")
        cases[tuple(values)] = expected

    for length in range(7):
        for values in product((-2, -1, 0, 1, 2), repeat=length):
            cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    for _ in range(512):
        length = rng.randrange(1, MAX_LENGTH + 1)
        values = [signed_i64(rng) for _ in range(length)]
        cases[tuple(values)] = oracle(values)

        winner = signed_i64(rng)
        majority_count = length // 2 + 1
        array = [winner] * majority_count
        array.extend(signed_i64(rng) for _ in range(length - majority_count))
        rng.shuffle(array)
        cases[tuple(array)] = oracle(array)

    for values in (
        (I64_MIN,), (I64_MAX,), (I64_MIN, I64_MAX),
        (I64_MIN, 0, I64_MIN, I64_MAX, I64_MIN),
        (I64_MAX, -1, I64_MAX, 0, I64_MAX),
        tuple([17] * 129 + [-4] * 127),
        tuple(range(MAX_LENGTH)),
        (17,) * (MAX_LENGTH + 1),
        (),
    ):
        cases[values] = oracle(list(values))

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(
        ALGORITHM,
        language,
        directory,
        compiler=elisa_compiler if language == "elisa" else None,
        with_checker=True,
        family="i64_array_scalar",
    )
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")

    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")

    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/boyer_moore_majority_vote")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/b/boyer_moore_majority_vote/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "oracle-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, directory / ALGORITHM / language,
                            args.elisa_compiler, data, case_count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)

    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "results": sorted(results, key=lambda item: item["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
