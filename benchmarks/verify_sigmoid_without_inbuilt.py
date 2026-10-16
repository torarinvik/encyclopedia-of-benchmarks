#!/usr/bin/env python3
"""Verify parameterized sigmoid ports through the two-input binary64 ABI."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_pair import encode_case, matches
from sigmoid_without_inbuilt_oracle import (
    INVALID_RESULT,
    SLOPE_MAX,
    SLOPE_MIN,
    X_MAX,
    X_MIN,
    expected_result as sigmoid_oracle,
)

ALGORITHM = "sigmoid_without_inbuilt"


def corpus(workload: dict) -> tuple[str, int]:
    timing = workload["measurement"]
    tolerance = float(timing.get("relative_tolerance", timing.get("input_scaled_tolerance", 0.0)))
    absolute = float(timing.get("absolute_tolerance", 0.0))
    if workload.get("algorithm") != ALGORITHM:
        raise ValueError("workload must name sigmoid_without_inbuilt")
    input_spec = workload["input"]
    if (input_spec.get("layout") != ["x", "a"]
            or input_spec.get("x_minimum") != X_MIN or input_spec.get("x_maximum") != X_MAX
            or input_spec.get("slope_minimum") != SLOPE_MIN
            or input_spec.get("slope_maximum") != SLOPE_MAX
            or input_spec.get("invalid_input_result") != INVALID_RESULT):
        raise ValueError("sigmoid workload bounds/order/sentinel disagree with the pinned oracle")

    pairs: dict[tuple[float, float], float] = {}

    def add(x: float, slope: float) -> None:
        expected = sigmoid_oracle(x, slope)
        encoded = encode_case({"input_values": [x, slope], "expected_result": expected},
                              tolerance, ALGORITHM, absolute)
        x, slope, expected = encoded
        exact = sigmoid_oracle(x, slope)
        if not matches(expected, exact, tolerance, x, slope, absolute):
            raise ValueError(f"sigmoid expected value disagrees with oracle at ({x}, {slope})")
        pairs[(x, slope)] = exact

    for case in workload["cases"]:
        x, slope, expected = encode_case(case, tolerance, ALGORITHM, absolute)
        exact = sigmoid_oracle(x, slope)
        if not matches(expected, exact, tolerance, x, slope, absolute):
            raise ValueError(f"workload disagrees with independent sigmoid oracle: {case['id']}")
        pairs[(x, slope)] = exact

    # Check the inclusive box, both signs, zero slope/input, and saturation edges.
    for x in (X_MIN, -5.0, -1.0, -0.0, 0.0, 1.0, 5.0, X_MAX):
        for slope in (SLOPE_MIN, -1.0, 0.0, 1.0, SLOPE_MAX):
            add(x, slope)

    # Finite values just beyond each edge are invalid-domain canaries.
    for x, slope in (
        (X_MIN - 1e-9, 1.0), (X_MAX + 1e-9, 1.0),
        (1.0, SLOPE_MIN - 1e-9), (1.0, SLOPE_MAX + 1e-9),
    ):
        add(x, slope)

    rng = random.Random(20261016)
    for _ in range(128):
        add(rng.uniform(X_MIN, X_MAX), rng.uniform(SLOPE_MIN, SLOPE_MAX))

    # The JSON workload intentionally contains finite values only. These direct ABI rows
    # exercise each scalar argument's NaN and infinity guard in every language port.
    nonfinite_pairs = (
        (math.nan, 1.0), (math.inf, 1.0), (-math.inf, 1.0),
        (1.0, math.nan), (1.0, math.inf), (1.0, -math.inf),
    )
    rows = [f"{len(pairs) + len(nonfinite_pairs)}\n"]
    for (x, slope), expected in sorted(pairs.items()):
        scaled_tolerance = max(tolerance, absolute / max(1.0, abs(x), abs(slope)))
        rows.append(" ".join(format(value, ".17g")
                             for value in (x, slope, expected, scaled_tolerance)) + "\n")
    for x, slope in nonfinite_pairs:
        if sigmoid_oracle(x, slope) != INVALID_RESULT:
            raise ValueError("non-finite sigmoid canaries must use the invalid-input sentinel")
        rows.append(" ".join(format(value, ".17g")
                             for value in (x, slope, INVALID_RESULT, tolerance)) + "\n")
    return "".join(rows), len(pairs) + len(nonfinite_pairs)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_pair")
    checker = manifest["binaries"]["float64_pair_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"sigmoid C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete sigmoid oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_float64_pair.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    timing = workload["measurement"]
    tolerance = float(timing.get("relative_tolerance", timing.get("input_scaled_tolerance", 0.0)))
    absolute = float(timing.get("absolute_tolerance", 0.0))
    for case, record in zip(workload["cases"], records):
        x, slope, expected = encode_case(case, tolerance, ALGORITHM, absolute)
        observed = float(record["measurement"]["observed_result"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != [x, slope]
                or record["workload"]["expected_result"] != expected
                or not matches(observed, sigmoid_oracle(x, slope), tolerance, x, slope, absolute)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/float64_pair/sigmoid_without_inbuilt")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    workload = json.loads((ROOT / "benchmarks/s/sigmoid_without_inbuilt/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "sigmoid-without-inbuilt-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle pairs", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "corpus_sha256": sha256_file(corpus_path),
              "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
