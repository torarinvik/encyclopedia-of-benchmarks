#!/usr/bin/env python3
"""Check the portable shape-area batch against an independent integer oracle."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "area"
MAX_OPERATIONS = 256
MAX_INPUT_VALUES = 1 + 4 * MAX_OPERATIONS
DIMENSION_LIMIT = 1000
OFFSET = 1_000_000_007
REGULAR_AREA_COEFFICIENTS = {
    3: 433_012_701, 4: 1_000_000_000, 5: 1_720_477_400, 6: 2_598_076_211,
    7: 3_633_912_444, 8: 4_828_427_124, 9: 6_181_824_193, 10: 7_694_208_842,
    11: 9_365_639_906, 12: 11_196_152_422, 13: 13_185_768_328, 14: 15_334_501_936,
    15: 17_642_362_910, 16: 20_109_357_968, 17: 22_735_491_898, 18: 25_520_768_188,
    19: 28_465_189_427, 20: 31_568_757_573, 21: 34_831_474_123, 22: 38_253_340_244,
    23: 41_834_356_852, 24: 45_574_524_676, 25: 49_473_844_301, 26: 53_532_316_204,
    27: 57_749_940_771, 28: 62_126_718_324, 29: 66_662_649_129, 30: 71_357_733_406,
    31: 76_211_971_344, 32: 81_225_363_100,
}


def scale_pi(value: int) -> int:
    return value * 3 + value * 141_592_654 // 1_000_000_000


def scale_pi_squared(value: int) -> int:
    return value * 9 + value * 869_604_401 // 1_000_000_000


def oracle(values: list[int] | tuple[int, ...]) -> int:
    if not 1 <= len(values) <= MAX_INPUT_VALUES:
        return -1
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 4 * count:
        return -1
    checksum = 0
    for index in range(count):
        operation, a, b, c = values[1 + 4 * index:5 + 4 * index]
        if not 0 <= operation <= 21 or any(not 0 <= value <= DIMENSION_LIMIT for value in (a, b, c)):
            return -1
        if operation in (0, 3, 9, 11, 12) and (b != 0 or c != 0):
            return -1
        if operation in (1, 2, 4, 7, 8, 13, 14, 15, 16, 17, 19, 20) and c != 0:
            return -1
        if operation == 0:
            result = a * a * 1000
        elif operation == 1:
            result = a * b * 1000
        elif operation == 2:
            result = a * b * 500
        elif operation == 3:
            result = scale_pi(a * a * 1000)
        elif operation == 4:
            result = a * b * 1000
        elif operation == 5:
            result = (a + b) * c * 500
        elif operation == 6:
            perimeter = a + b + c
            if a + b < c or a + c < b or b + c < a:
                return -1
            radicand = perimeter * (perimeter - 2 * a) * (perimeter - 2 * b) * (perimeter - 2 * c)
            result = math.isqrt(radicand * 1_000_000) // 4
        elif operation == 7:
            result = scale_pi(a * b * 1000)
        elif operation == 8:
            result = a * b * 500
        elif operation == 9:
            result = 6 * a * a * 1000
        elif operation == 10:
            result = 2 * (a * b + a * c + b * c) * 1000
        elif operation == 11:
            result = scale_pi(4 * a * a * 1000)
        elif operation == 12:
            result = scale_pi(3 * a * a * 1000)
        elif operation == 13:
            result = scale_pi(2 * a * (b + a) * 1000)
        elif operation == 14:
            result = scale_pi(2 * a * b * 1000)
        elif operation == 15:
            result = scale_pi(a * a * 1000 + a * math.isqrt((a * a + b * b) * 1_000_000))
        elif operation == 16:
            result = scale_pi(a * math.isqrt((a * a + b * b) * 1_000_000))
        elif operation == 17:
            result = (a * a + 2 * a * b) * 1000
        elif operation == 18:
            difference = abs(a - b)
            slant_milli = math.isqrt((c * c + difference * difference) * 1_000_000)
            result = scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli)
        elif operation == 19:
            result = scale_pi_squared(4 * a * b * 1000)
        elif operation == 20:
            coefficient = REGULAR_AREA_COEFFICIENTS.get(a)
            if coefficient is None:
                return -1
            result = coefficient * b * b // 1_000_000
        else:
            coefficient = REGULAR_AREA_COEFFICIENTS.get(a)
            if coefficient is None:
                return -1
            result = 2 * (coefficient * b * b // 1_000_000) + a * b * c * 1000
        checksum += (index + 1) * (result + OFFSET)
    return checksum


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def include(values) -> None:
        packed = tuple(values)
        cases[packed] = oracle(packed)

    # Exercise every formula over the same small dimension cube.
    for operation in range(22):
        for a, b, c in itertools.product(range(7), repeat=3):
            include((1, operation, a, b, c))

    rng = random.Random(20261014)
    for _ in range(1024):
        count = rng.randrange(MAX_OPERATIONS + 1)
        packed = [count]
        for _operation in range(count):
            packed.extend((rng.randrange(22), rng.randrange(DIMENSION_LIMIT + 1),
                           rng.randrange(DIMENSION_LIMIT + 1), rng.randrange(DIMENSION_LIMIT + 1)))
        include(packed)

    include((MAX_OPERATIONS, *(value for _index in range(MAX_OPERATIONS)
                               for value in (0, 4, 0, 0))))
    malformed = [
        (), (-1,), (MAX_OPERATIONS + 1,), (1,), (1, 22, 0, 0, 0),
        (1, 0, 1, 0, 0), (1, 3, DIMENSION_LIMIT + 1, 0, 0),
        (1, 6, 1, 2, 4), (1, 18, 1, 1, DIMENSION_LIMIT + 1),
        (1, 0, 1, 0, 0, 999),
        tuple([0] + [0] * (MAX_INPUT_VALUES)),
    ]
    for values in malformed:
        include(values)
    for _ in range(512):
        size = rng.randrange(0, 65)
        include(tuple(rng.choice((-1, 0, 1, 2, 3, 19, 21, 22, 256, 257,
                                  DIMENSION_LIMIT + 1, -DIMENSION_LIMIT - 1))
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
    if checked.returncode or json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError(f"array-scalar C ABI checker failed: {checked.stderr}")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
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
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/a/area/workload.json"),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/a/area")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language choices must be unique")
    workload = json.loads((ROOT / "benchmarks/a/area/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    failures, results = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        pending = {pool.submit(verify, language, args.build_dir.resolve() / language,
                               args.elisa_compiler, data, case_count, workload): language
                   for language in args.languages}
        for job in as_completed(pending):
            language = pending[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({"language": language, "error": str(exc)})
                print(f"FAIL area/{language}: {exc}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS area/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures and len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"]), "failures": failures}
    args.build_dir.resolve().mkdir(parents=True, exist_ok=True)
    (args.build_dir.resolve() / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {args.build_dir.resolve() / 'verification.json'}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
