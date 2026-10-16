#!/usr/bin/env python3
"""Check float64 slice-to-slice ports against their independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import math
from pathlib import Path
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_slice_io import ORACLES, _format_output, encode_case, tolerances

ALGORITHMS = tuple(ORACLES)


def checker_records(algorithm: str, workload: dict) -> tuple[str, int]:
    absolute_tolerance, relative_tolerance = tolerances(workload)
    workspace = workload.get("workspace", {}).get("elements")
    if type(workspace) is not int or not 1 <= workspace <= 64:
        raise ValueError("workspace.elements must be an integer from 1 through 64")
    records: list[tuple[list[float], int, list[float | str], int, int, int]] = []
    valid_case: tuple[list[float], int, list[float | str]] | None = None
    for case in workload.get("cases", []):
        values, expected_result, expected_output = encode_case(
            case, algorithm, absolute_tolerance, relative_tolerance)
        if expected_result >= 0 and expected_result > workspace:
            raise ValueError(f"workspace is too small for {case.get('id')}")
        records.append((values, expected_result, expected_output, workspace, 0, 0))
        if expected_result > 0 and valid_case is None:
            valid_case = (values, expected_result, expected_output)

    if not records:
        raise ValueError("workload requires at least one case")
    if valid_case is None:
        raise ValueError("workload requires a successful output case for ABI boundary checks")
    values, result_count, _ = valid_case
    records.append((values, -2, [], result_count - 1, 0, 0))
    records.append((values, -2, [], workspace, 0, 1))
    records.extend((
        ([0.0] * 4, -1, [], workspace, 0, 0),
        ([0.0] * 6, -1, [], workspace, 0, 0),
        (values, -1, [], workspace, 1, 0),
        ([], -1, [], workspace, 0, 0),
    ))

    lines = [f"{len(records)} {absolute_tolerance:.17g} {relative_tolerance:.17g} {workspace}\n"]
    for inputs, expected_result, expected_output, capacity, input_null, output_null in records:
        lines.append(f"{len(inputs)} {expected_result} {len(expected_output)} {capacity} "
                     f"{input_null} {output_null}\n")
        if inputs:
            lines.append(" ".join(format(value, ".17g") for value in inputs) + "\n")
        if expected_output:
            lines.append(" ".join(_format_output(value) for value in expected_output) + "\n")
    return "".join(lines), len(records)


def _matches_output(observed: object, expected: list[float | str],
                    absolute_tolerance: float, relative_tolerance: float) -> bool:
    if not isinstance(observed, list) or len(observed) != len(expected):
        return False
    for actual, reference in zip(observed, expected):
        if reference == "NaN":
            if actual != "NaN":
                return False
            continue
        if type(actual) not in (int, float) or not math.isfinite(float(actual)):
            return False
        target = float(reference)
        if abs(float(actual) - target) > absolute_tolerance + relative_tolerance * abs(target):
            return False
    return True


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_slice_io")
    checker = manifest["binaries"]["float64_slice_io_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"float64-slice C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete float64-slice corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_float64_slice_io.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    absolute_tolerance, relative_tolerance = tolerances(workload)
    for case, record in zip(workload["cases"], records):
        values, expected_result, expected_output = encode_case(
            case, algorithm, absolute_tolerance, relative_tolerance)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_result
                or record["workload"]["expected_output"] != expected_output
                or record["measurement"]["comparison_model"] != "float64_slice_io_call"
                or record["measurement"]["observed_result"] != expected_result
                or not _matches_output(record["measurement"]["observed_output"], expected_output,
                                       absolute_tolerance, relative_tolerance)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", choices=ALGORITHMS, required=True)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    algorithm = args.algorithm
    workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != algorithm:
        parser.error("workload algorithm does not match the requested algorithm")
    data, count = checker_records(algorithm, workload)
    build_root = (args.build_dir or ROOT / "build" / "float64_slice_io" / algorithm).resolve()
    build_root.mkdir(parents=True, exist_ok=True)
    (build_root / f"{algorithm}-corpus.txt").write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {
            pool.submit(verify, algorithm, language, build_root / language,
                        args.elisa_compiler, data, count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
                results.append(result)
                print(f"PASS {language}: {count} ABI cases, {result['workload_records']} workload records",
                      flush=True)
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {language}: {error}", file=sys.stderr, flush=True)
    report = {"algorithm": algorithm, "results": sorted(results, key=lambda result: result["language"]),
              "failures": failures}
    (build_root / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
