#!/usr/bin/env python3
"""Verify trace-driven Barnsley fern ports against the pinned affine maps."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from barnsley_fern_oracle import expected_output
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "barnsley_fern"
WORKLOAD_PATH = ROOT / "benchmarks/b/barnsley_fern/workload.json"
SAMPLES_FOR_MAP = (0, 100, 8_600, 9_300)


def corpus(workload: dict) -> tuple[str, int, dict[tuple[int, ...], tuple[int, bytes]]]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def include(values: tuple[int, ...], declared: tuple[int, str] | None = None) -> None:
        result = expected_output(list(values))
        if declared is not None and (result[0] != declared[0] or result[1].hex() != declared[1]):
            raise ValueError("published fern workload differs from the source-map oracle")
        cases[values] = result

    for case in workload["cases"]:
        include(tuple(case["input_values"]),
                (case["expected_result"], case["expected_output_hex"]))

    sequences = [()]
    for length in range(1, 8):
        sequences.extend(tuple(SAMPLES_FOR_MAP[index] for index in encoded)
                         for encoded in product(range(4), repeat=length))
    for samples in sequences:
        include((len(samples) + 1, *samples))

    rng = random.Random(20261015)
    lengths = (1, 2, 17, 255, 512, 2048, 4096)
    for _ in range(512):
        iterations = rng.choice(lengths)
        include((iterations, *(rng.randrange(10_000) for _ in range(iterations - 1))))

    for invalid in ((), (0,), (4097,), (2,), (2, -1), (2, 10_000),
                    (1, 0), (3, 0, 1, 2), (1, 9_223_372_036_854_775_808)):
        include(invalid)

    records = sorted(cases.items())
    records.append(((1,), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {output.hex() if output else '-'}\n")
    return "".join(lines), len(records), dict(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int,
           cases: dict[tuple[int, ...], tuple[int, bytes]], workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"fern byte-output ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete fern corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"fern workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of fern records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        expected_result, expected_bytes = cases[values]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["expected_result"] != expected_result
                or record["measurement"]["observed_result"] != expected_result
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)):
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
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/barnsley_fern")
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    checker_input, case_count, cases = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language, args.build_dir / language,
                            args.elisa_compiler, checker_input, case_count, cases, workload): language
            for language in args.languages
        }
        for future in as_completed(futures):
            language = futures[future]
            try:
                results.append(future.result())
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
    results.sort(key=lambda item: item["language"])
    report = {"algorithm": ALGORITHM,
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures and len(results) == len(args.languages),
              "oracle_cases_per_language": case_count,
              "results": results, "failures": failures}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "passed" if report["all_passed"] else "failed",
                      "oracle_cases_per_language": case_count,
                      "languages": [entry["language"] for entry in results],
                      "report": str(report_path)}, indent=2))
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
