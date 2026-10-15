#!/usr/bin/env python3
"""Compile and check Faraday-Lenz ports with exact fixed-point arithmetic."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "faraday_lenz_law"
INVALID = -(2**63)


def oracle(values: list[int]) -> int:
    if (len(values) != 3 or any(type(value) is not int for value in values)
            or not -1_000_000_000 <= values[0] <= 1_000_000_000
            or not -1_000_000_000 <= values[1] <= 1_000_000_000
            or not 1 <= values[2] <= 1_000_000_000):
        return INVALID
    numerator = -(values[0] - values[1]) * 10
    sign = -1 if numerator < 0 else 1
    quotient, remainder = divmod(abs(numerator), values[2])
    if 2 * remainder > values[2] or (2 * remainder == values[2] and quotient % 2):
        quotient += 1
    return sign * quotient


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        if encode_case(case, ALGORITHM) != list(values):
            raise ValueError(f"array-scalar runner rejected workload case: {case['id']}")
        cases[values] = expected
    flux_values = (-1000, -150, -25, -7, -5, 0, 5, 7, 25, 150, 1000)
    intervals = (1, 2, 3, 5, 10, 20, 100, 1000, 1_000_000)
    for final_flux, initial_flux, interval in itertools.product(flux_values, flux_values, intervals):
        values = (final_flux, initial_flux, interval)
        cases[values] = oracle(list(values))
    rng = random.Random(20261015)
    for _ in range(512):
        values = (rng.randint(-1_000_000_000, 1_000_000_000),
                  rng.randint(-1_000_000_000, 1_000_000_000),
                  rng.randint(1, 1_000_000_000))
        cases[values] = oracle(list(values))
    for values in ((), (0, 1), (0, 1, 2, 3), (1_000_000_001, 0, 1),
                   (0, -1_000_000_001, 1), (0, 0, 0), (0, 0, -2), (0, 0, 1_000_000_001)):
        cases[values] = oracle(list(values))
    lines = [f"{len(cases)}\n"]
    lines.extend(f"{len(values)} {expected}" + (" " + " ".join(map(str, values)) if values else "") + "\n"
                 for values, expected in sorted(cases.items()))
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"integer scalar C ABI check failed: {checked.stderr}")
    observed = json.loads(checked.stdout)["cases_checked"]
    if observed != case_count:
        raise RuntimeError(f"checker consumed {observed} of {case_count} cases")
    return {"language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/faraday_lenz_law")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    workload = json.loads((ROOT / "benchmarks/f/faraday_lenz_law/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} checker cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages)
              and all(item["status"] == "passed" for item in results),
              "corpus_sha256": sha256_file(corpus_path),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
