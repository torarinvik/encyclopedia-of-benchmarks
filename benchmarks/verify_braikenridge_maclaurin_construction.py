#!/usr/bin/env python3
"""Verify five-point conic determinant ports against a permutation oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import combinations, permutations, product
import json
from pathlib import Path
import random
import subprocess
import sys

from braikenridge_maclaurin_construction_oracle import (
    MAX_ABS_COORDINATE,
    expected_output,
)
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output as recorder_expected_output
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "braikenridge_maclaurin_construction"
WORKLOAD_PATH = ROOT / "benchmarks/b/braikenridge_maclaurin_construction/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
POINTS = tuple(product((-1, 0, 1), repeat=2))


def oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Rebuild each source matrix and expand its determinant over permutations."""
    if (not isinstance(values, (tuple, list)) or len(values) != 10
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or any(not -MAX_ABS_COORDINATE <= value <= MAX_ABS_COORDINATE for value in values)):
        return -2, b""
    points = [(values[index], values[index + 1]) for index in range(0, 10, 2)]
    features = [(x * x, x * y, y * y, x, y, 1) for x, y in points]
    column_maps = (
        (1, 2, 3, 4, 5), (0, 2, 3, 4, 5), (0, 1, 3, 4, 5),
        (0, 1, 2, 4, 5), (0, 1, 2, 3, 5), (0, 1, 2, 3, 4),
    )
    coefficients = []
    for index, columns in enumerate(column_maps):
        matrix = [[feature[column] for column in columns] for feature in features]
        determinant = 0
        for permutation in permutations(range(5)):
            inversions = sum(permutation[i] > permutation[j]
                             for i in range(5) for j in range(i + 1, 5))
            term = 1
            for row in range(5):
                term *= matrix[row][permutation[row]]
            determinant += -term if inversions & 1 else term
        coefficients.append(-determinant if index & 1 else determinant)
    output = b"".join(value.to_bytes(8, "little", signed=True) for value in coefficients)
    return 6, output


def corpus(workload: dict) -> tuple[str, int, dict[tuple[tuple[int, ...], int], tuple[int, bytes]]]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
    default_capacity = workload["workspace"]["bytes"]

    def add(values: tuple[int, ...] | list[int], capacity: int = default_capacity) -> None:
        packed = tuple(values)
        required = oracle(packed)
        if recorder_expected_output(list(packed), ALGORITHM) != required:
            raise ValueError(f"independent and recorder oracles disagree for {packed}")
        actual = (-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required
        cases[(packed, capacity)] = actual

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        required = oracle(values)
        capacity = case.get("workspace_bytes", default_capacity)
        result, payload = ((-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required)
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != result
                or case.get("expected_output_hex") != payload.hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values, capacity)

    for point_set in combinations(POINTS, 5):
        for ordered in (point_set, tuple(reversed(point_set))):
            add(tuple(value for point in ordered for value in point))

    rng = random.Random(20261015)
    for _ in range(1024):
        points = [(rng.randrange(-MAX_ABS_COORDINATE, MAX_ABS_COORDINATE + 1),
                   rng.randrange(-MAX_ABS_COORDINATE, MAX_ABS_COORDINATE + 1))
                  for _ in range(5)]
        add(tuple(value for point in points for value in point))

    for invalid in (
        (), (0,) * 8, (0,) * 9, (0,) * 11, (I64_MIN,) * 10, (I64_MAX,) * 10,
        (11, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (0, -11, 0, 0, 0, 0, 0, 0, 0, 0),
    ):
        add(tuple(invalid))

    source_example = tuple(workload["cases"][0]["input_values"])
    for capacity in (0, 1, 7, 8, 47, 48):
        add(source_example, capacity)

    records = sorted(cases.items(), key=lambda item: (item[0][0], item[0][1]))
    lines = [f"{len(records)}\n"]
    for (values, capacity), (result, payload) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(payload)} {capacity}{suffix} {payload.hex() or '-'}\n")
    return "".join(lines), len(records), cases


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int, cases: dict,
           workload: dict) -> dict:
    link_shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
                  if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output",
                     extra_link_sources=link_shims)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"determinant ABI check failed: {checked.stdout}\n{checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("determinant checker did not consume the complete oracle corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        required = oracle(values)
        capacity = case.get("workspace_bytes", len(required[1]))
        expected = (-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["output_capacity"] != capacity
                or record["workload"]["expected_result"] != expected[0]
                or record["measurement"]["observed_result"] != expected[0]
                or record["measurement"]["result_checksum"] != fnv1a(expected[1])):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/b/braikenridge_maclaurin_construction")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count, cases = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "braikenridge-maclaurin-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, cases, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(report_path)
    return 0 if all(item["status"] == "passed" for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
