#!/usr/bin/env python3
"""Check float64 slice-to-slice ports against their independent oracles."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import math
from pathlib import Path
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_slice_io import (MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH, ORACLES,
                                  _format_output, encode_case, tolerances)

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
    for invalid_length in (4, 6):
        invalid_input = [0.0] * invalid_length
        if ORACLES[algorithm](invalid_input) is None:
            records.append((invalid_input, -1, [], workspace, 0, 0))
    records.extend(((values, -1, [], workspace, 1, 0),
                    ([], -1, [], workspace, 0, 0)))

    if algorithm == "rayleigh_quotient":
        oracle = ORACLES[algorithm]

        def add_rayleigh_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        rng = random.Random(20261016)
        for _ in range(128):
            dimension = rng.randint(1, 16)
            matrix = [0.0] * (dimension * dimension)
            for row in range(dimension):
                for col in range(row, dimension):
                    value = rng.uniform(-1000.0, 1000.0)
                    matrix[row * dimension + col] = value
                    matrix[col * dimension + row] = value
            vector = [rng.uniform(-100.0, 100.0) for _ in range(dimension)]
            if all(value == 0.0 for value in vector):
                vector[0] = 1.0
            inputs = [float(dimension), *matrix, *vector]
            if len(inputs) > MAX_RAYLEIGH_QUOTIENT_INPUT_LENGTH:
                raise ValueError("rayleigh_quotient generated input exceeds its reviewed bound")
            add_rayleigh_case(inputs)

        boundary_matrix = [1000.0, -1000.0, -1000.0, -1000.0]
        add_rayleigh_case([2.0, *boundary_matrix, -100.0, 100.0])
        invalid_cases = (
            [0.0], [17.0], [1.5], [1.0, 1.0], [1.0, 1.0, 1.0, 0.0],
            [2.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0],
            [1.0, -1000.000001, 1.0], [1.0, 1000.000001, 1.0],
            [1.0, 1.0, -100.000001], [1.0, 1.0, 100.000001],
            [1.0, 1.0, 0.0], [1.0, math.nan, 1.0],
            [1.0, math.inf, 1.0], [1.0, 1.0, math.inf],
        )
        for inputs in invalid_cases:
            if oracle(inputs) is not None:
                raise ValueError("rayleigh_quotient oracle accepted a malformed probe")
            add_rayleigh_case(inputs)
    elif algorithm == "fresnel_diffract":
        oracle = ORACLES[algorithm]

        def add_fresnel_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # The fixed physical prefix is part of this bounded ABI contract.
        for index, replacement in ((0, 3.0), (1, 0.0), (2, 2.0), (3, 15.0)):
            invalid_parameters = list(values)
            invalid_parameters[index] = replacement
            add_fresnel_case(invalid_parameters)

        # Exercise both accepted range endpoints and just-outside values.
        boundary_values = list(values)
        boundary_values[4], boundary_values[8] = 100.0, -100.0
        add_fresnel_case(boundary_values)
        for index, replacement in ((4, 100.000001), (5, -100.000001),
                                   (8, 100.000001), (11, -100.000001)):
            out_of_range = list(values)
            out_of_range[index] = replacement
            add_fresnel_case(out_of_range)

        for special in (math.nan, math.inf, -math.inf):
            nonfinite = list(values)
            nonfinite[4] = special
            add_fresnel_case(nonfinite)

        add_fresnel_case(values[:-1])
        add_fresnel_case([*values, 0.0])
    elif algorithm == "softmax":
        oracle = ORACLES[algorithm]
        for invalid_logit in (20.000001, -20.000001, math.nan, math.inf, -math.inf):
            invalid_input = [invalid_logit]
            if oracle(invalid_input) is not None:
                raise ValueError("softmax oracle must reject out-of-range and non-finite logits")
            records.append((invalid_input, -1, [], workspace, 0, 0))
    elif algorithm == "trig_functions":
        oracle = ORACLES[algorithm]

        def add_trig_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Valid non-finite x is deliberately represented by one NaN output.
        for special_x in (math.nan, math.inf, -math.inf):
            add_trig_case([0.0, special_x, 1e-9])

        # Cover the accepted finite x endpoints and the immediately out-of-range values.
        for boundary_x in (-10_000.0, 10_000.0):
            add_trig_case([0.0, boundary_x, 1e-9])
        for invalid_x in (-10_000.000001, 10_000.000001):
            add_trig_case([0.0, invalid_x, 1e-9])

        for invalid_selector in (-1.0, 8.0, 1.5, math.nan, math.inf):
            add_trig_case([invalid_selector, 0.0, 1e-9])
        for invalid_tolerance in (0.0, 0.999e-9, 0.010000001, math.nan, math.inf):
            add_trig_case([0.0, 0.0, invalid_tolerance])

        # This operation requires exactly three input values.
        add_trig_case([0.0, 0.0])
    elif algorithm == "verlet":
        oracle = ORACLES[algorithm]

        def add_verlet_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Every input slot must be finite, even when all other fields are valid.
        valid_input = [2.0, 0.25, -0.5, 2.0]
        for index in range(4):
            for special in (math.nan, math.inf, -math.inf):
                invalid_input = list(valid_input)
                invalid_input[index] = special
                add_verlet_case(invalid_input)

        for invalid_input in (
            [1.5, 0.0, 0.0, 0.0], [1.0, 0.0, 0.0, 0.0],
            [32.5, 0.0, 0.0, 0.0], [2.0, -1.000001, 0.0, 0.0],
            [2.0, 1.000001, 0.0, 0.0], [2.0, 0.0, -1.000001, 0.0],
            [2.0, 0.0, 1.000001, 0.0], [2.0, 0.0, 0.0, -1.0],
            [2.0, 0.0, 0.0, 5.0], [2.0, 0.0, 0.0, 1.5],
            [2.0, 0.0, 0.0],
        ):
            add_verlet_case(invalid_input)
    elif algorithm == "vector2":
        oracle = ORACLES[algorithm]

        def add_vector2_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        # Every ABI slot is numeric and finite, including operation selectors and
        # fields that are otherwise unused by a selected operation.
        valid_add = [4.0, 1.25, -2.5, 3.5, 4.25, 0.0]
        for index in range(6):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_add)
                nonfinite[index] = special
                add_vector2_case(nonfinite)

        for invalid_selector in (-1.0, 11.0, 2.5, math.nan, math.inf):
            add_vector2_case([invalid_selector, 0.0, 0.0, 0.0, 0.0, 0.0])

        # Coordinates have a closed [-1000, 1000] domain. Probe each field
        # outside it and include the accepted endpoints on an active operation.
        for index in range(1, 5):
            for invalid_coordinate in (-1000.000001, 1000.000001):
                invalid = list(valid_add)
                invalid[index] = invalid_coordinate
                add_vector2_case(invalid)
        add_vector2_case([4.0, -1000.0, 1000.0, 1000.0, -1000.0, 0.0])

        # Approximate equality uses epsilon in [0, 2000], including both ends.
        for epsilon in (0.0, 2000.0):
            add_vector2_case([1.0, 0.0, 0.0, 1.0, -1.0, epsilon])
        for invalid_epsilon in (-0.000001, 2000.000001):
            add_vector2_case([1.0, 0.0, 0.0, 1.0, -1.0, invalid_epsilon])

        # Multiplication and rotation are the only operations that consume the
        # final field. Their endpoints are valid; just-outside values are not.
        for factor in (-1000.0, 1000.0):
            add_vector2_case([6.0, 1.0, -1.0, 0.0, 0.0, factor])
        for invalid_factor in (-1000.000001, 1000.000001):
            add_vector2_case([6.0, 1.0, -1.0, 0.0, 0.0, invalid_factor])
        angle_limit = 2.0 * math.pi
        for angle in (-angle_limit, angle_limit):
            add_vector2_case([9.0, 1.0, 0.0, 0.0, 0.0, angle])
        for invalid_angle in (-angle_limit - 0.000001, angle_limit + 0.000001):
            add_vector2_case([9.0, 1.0, 0.0, 0.0, 0.0, invalid_angle])

        # Each operation has an unambiguous encoding: unused coordinates and
        # scalar slots must be zero. Cover each distinct validation rule.
        for malformed_unused in (
            [0.0, 1.0, 2.0, 1.0, 2.0, 1.0],
            [2.0, 3.0, 4.0, 1.0, 0.0, 0.0],
            [2.0, 3.0, 4.0, 0.0, 1.0, 0.0],
            [2.0, 3.0, 4.0, 0.0, 0.0, 1.0],
            [3.0, 3.0, 4.0, 1.0, 0.0, 0.0],
            [3.0, 3.0, 4.0, 0.0, 1.0, 0.0],
            [3.0, 3.0, 4.0, 0.0, 0.0, 1.0],
            [4.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [5.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [6.0, 1.0, 2.0, 1.0, 0.0, 2.0],
            [6.0, 1.0, 2.0, 0.0, 1.0, 2.0],
            [7.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [8.0, 1.0, 2.0, 3.0, 4.0, 1.0],
            [9.0, 1.0, 2.0, 1.0, 0.0, 0.5],
            [9.0, 1.0, 2.0, 0.0, 1.0, 0.5],
            [10.0, 1.0, 2.0, 3.0, 4.0, 1.0],
        ):
            add_vector2_case(malformed_unused)

        # The source rejects normalization when computed length is zero,
        # including a nonzero vector whose squared components underflow.
        add_vector2_case([3.0, 0.0, 0.0, 0.0, 0.0, 0.0])
        add_vector2_case([3.0, 1e-200, 0.0, 0.0, 0.0, 0.0])

        # The operation tuple must contain exactly six values.
        add_vector2_case([4.0, 1.0, 2.0, 3.0, 4.0])
        add_vector2_case([4.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0])

        # The shared capacity probe uses a scalar-returning first workload
        # case, so separately reject capacity one for a valid vector result.
        records.append((valid_add, -2, [], 1, 0, 0))
    elif algorithm == "projectile_motion":
        oracle = ORACLES[algorithm]

        def add_projectile_case(inputs: list[float]) -> None:
            expected_output = oracle(inputs)
            expected_result = -1 if expected_output is None else len(expected_output)
            records.append((inputs, expected_result,
                            [] if expected_output is None else expected_output,
                            workspace, 0, 0))

        valid_input = [250.0, 37.0, 12.5, 9.80665]
        # Every parameter must be finite before the trajectory formulas run.
        for index in range(4):
            for special in (math.nan, math.inf, -math.inf):
                nonfinite = list(valid_input)
                nonfinite[index] = special
                add_projectile_case(nonfinite)

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
    extra_link_sources = ()
    if language == "elisa" and elisa_compiler:
        runtime = Path(elisa_compiler).resolve().parent.parent / "build/runtime/elisacore_runtime.o"
        if runtime.is_file():
            extra_link_sources = (runtime,)
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_slice_io",
                     extra_link_sources=extra_link_sources)
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
