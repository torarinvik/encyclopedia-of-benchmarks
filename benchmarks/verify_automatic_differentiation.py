#!/usr/bin/env python3
"""Verify scalar reverse-mode ports against an independent forward-mode oracle."""

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

from automatic_differentiation_oracle import INVALID_RESULT, automatic_differentiation
from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "automatic_differentiation"
WORKLOAD_PATH = ROOT / "benchmarks/a/automatic_differentiation/workload.json"
ABS_TOL = 1e-12
REL_TOL = 1e-12


def forward_oracle(values: list[int]) -> float:
    """Evaluate one derivative with dual numbers, independently of reverse mode."""
    if automatic_differentiation(values) == INVALID_RESULT:
        return INVALID_RESULT
    leaves, operation_count, target, source = values[:4]
    nodes: list[tuple[float, float, bool]] = [
        (float(value), float(index == source), index == source)
        for index, value in enumerate(values[4:4 + leaves])
    ]
    offset = 4 + leaves
    for _ in range(operation_count):
        opcode, left, right = values[offset:offset + 3]
        left_value, left_derivative, left_reaches = nodes[left]
        if opcode == 5:
            result_value = left_value ** right
            result_derivative = right * (left_value ** (right - 1)) * left_derivative
            reaches_source = left_reaches
        else:
            right_value, right_derivative, right_reaches = nodes[right]
            reaches_source = left_reaches or right_reaches
            if opcode == 0:
                result_value = left_value + right_value
                result_derivative = left_derivative + right_derivative
            elif opcode == 1:
                result_value = left_value - right_value
                result_derivative = left_derivative - right_derivative
            elif opcode == 2:
                result_value = left_value * right_value
                result_derivative = left_derivative * right_value + left_value * right_derivative
            else:
                result_value = left_value / right_value
                result_derivative = (left_derivative * right_value - left_value * right_derivative) / (right_value * right_value)
        nodes.append((result_value, result_derivative, reaches_source))
        offset += 3
    value, derivative, connected = nodes[target]
    del value
    return derivative if connected else INVALID_RESULT


def corpus(workload: dict) -> list[tuple[int, ...]]:
    cases: dict[tuple[int, ...], float] = {}

    def include(values: tuple[int, ...], declared: float | None = None) -> None:
        reverse_value = automatic_differentiation(list(values))
        forward_value = forward_oracle(list(values))
        if not math.isclose(reverse_value, forward_value, rel_tol=REL_TOL, abs_tol=ABS_TOL):
            raise ValueError(f"forward/reverse oracle disagreement for {values[:8]}")
        if declared is not None and not math.isclose(
                declared, reverse_value, rel_tol=REL_TOL, abs_tol=ABS_TOL):
            raise ValueError("published workload differs from the reverse-mode oracle")
        cases[values] = forward_value

    for case in workload["cases"]:
        include(tuple(case["input_values"]), case["expected_result"])

    # Small explicit graphs exercise every supported local derivative rule.
    include((1, 1, 1, 0, 3, 5, 0))
    include((2, 2, 3, 0, 4, 2, 0, 1, 0, 1))
    include((2, 2, 3, 1, 4, -3, 2, 0, 0, 1, 3, 2, 0))
    for malformed in ((), (1, 1), (1, 1, 1), (0, 1, 1, 0), (1, 0, 1, 0, 3),
                      (1, 1, 0, 0, 3, 5, 0), (1, 1, 1, 1, 3, 5, 0),
                      (1, 1, 1, 0, 3, 4, 0), (1, 1, 1, 0, 3, 0, 0),
                      (2, 1, 2, 0, 1, 0, 0, 3, 0, 1),
                      (1, 1, 1, 0, 0, 3, 0), (1, 1, 1, 0, 17, 5, 0)):
        include(malformed)

    rng = random.Random(20261015)
    accepted = 0
    attempts = 0
    while accepted < 256 and attempts < 10000:
        attempts += 1
        leaves = rng.randrange(1, 7)
        operation_count = rng.randrange(1, 18)
        leaf_values = [rng.randrange(-4, 5) for _ in range(leaves)]
        nodes: list[float] = [float(value) for value in leaf_values]
        operations: list[tuple[int, int, int]] = []
        for operation in range(operation_count):
            output_node = leaves + operation
            opcode = rng.choice((0, 1, 2, 3, 5))
            left = rng.randrange(output_node)
            if opcode == 5:
                right = rng.randrange(1, 6)
                value = nodes[left] ** right
            else:
                available = [index for index in range(output_node)
                             if opcode != 3 or nodes[index] != 0]
                if not available:
                    opcode = 0
                    available = list(range(output_node))
                right = rng.choice(available)
                if opcode == 0: value = nodes[left] + nodes[right]
                elif opcode == 1: value = nodes[left] - nodes[right]
                elif opcode == 2: value = nodes[left] * nodes[right]
                else: value = nodes[left] / nodes[right]
            if not math.isfinite(value) or abs(value) > 1e10:
                break
            nodes.append(value)
            operations.append((opcode, left, right))
        if len(operations) != operation_count:
            continue
        target = rng.randrange(leaves, leaves + operation_count)
        source = rng.randrange(leaves)
        values = (leaves, operation_count, target, source, *leaf_values,
                  *(field for operation in operations for field in operation))
        include(values)
        accepted += 1

    if accepted != 256:
        raise RuntimeError("unable to generate the requested bounded tape corpus")
    return sorted(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           values_list: list[tuple[int, ...]], workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_float64")
    runner = Path(manifest["binaries"]["i64_array_float64_runner"]["path"])
    for values in values_list:
        expected = forward_oracle(list(values))
        command = [str(runner), str(len(values)), *map(str, values), repr(expected),
                   repr(ABS_TOL), repr(REL_TOL), "1", "0", "1"]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=30)
        if completed.returncode:
            raise RuntimeError(f"{language} result mismatch for {values[:8]}: {completed.stderr}")
        observed = float(json.loads(completed.stdout)["observed_result"])
        if not math.isclose(observed, expected, rel_tol=REL_TOL, abs_tol=ABS_TOL):
            raise RuntimeError(f"{language} result differs from forward oracle: {values[:8]}")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_float64.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        expected = forward_oracle(case["input_values"])
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != case["input_values"]
                or not math.isclose(record["measurement"]["observed_result"], expected,
                                    rel_tol=REL_TOL, abs_tol=ABS_TOL)):
            raise RuntimeError(f"workload record mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": len(values_list), "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_float64/automatic_differentiation")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages):
        parser.error("jobs must be between 1 and the selected language count")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    values_list = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language, args.build_dir / language,
                            args.elisa_compiler, values_list, workload): language
            for language in args.languages
        }
        for future in as_completed(futures): results.append(future.result())
    results.sort(key=lambda result: result["language"])
    report = {"schema_version": 1, "algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": {"system": platform.system(), "release": platform.release(),
                           "machine": platform.machine(), "python": platform.python_version()},
              "oracle_cases_per_language": len(values_list),
              "workload_records_per_language": len(workload["cases"]), "languages": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "oracle_cases_per_language": len(values_list),
                      "languages": [record["language"] for record in results],
                      "report": str(report_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
