#!/usr/bin/env python3
"""Check the minimum-grid-path ports against an independent row DP oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import permutations, product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "minimum_path_cost_in_grid"
MAX_DIMENSION = 32
INF_COST = 1_000_000_000


def encode_grid_case(case: dict) -> list[int]:
    if "input_values" in case:
        return encode_case(case, algorithm=ALGORITHM)
    grid = case.get("grid")
    move_cost = case.get("move_cost")
    if not isinstance(grid, list) or not isinstance(move_cost, list):
        raise ValueError(f"grid workload requires grid and move_cost: {case.get('id')}")
    rows = len(grid)
    columns = len(grid[0]) if rows and isinstance(grid[0], list) else 0
    return [rows, columns, *(value for row in grid for value in row),
            *(value for row in move_cost for value in row)]


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int for value in values[:2])):
        return -1
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_DIMENSION or not 1 <= columns <= MAX_DIMENSION:
        return -1
    cells = rows * columns
    move_offset = 2 + cells
    if len(values) != move_offset + cells * columns:
        return -1
    grid_values = values[2:move_offset]
    move_values = values[move_offset:]
    if any(type(value) is not int or not 0 <= value < cells for value in grid_values):
        return -1
    if any(type(value) is not int or not 1 <= value <= 100 for value in move_values):
        return -1
    grid = [grid_values[row * columns:(row + 1) * columns] for row in range(rows)]
    moves = [move_values[row * columns:(row + 1) * columns] for row in range(cells)]
    costs = [0] * columns
    for row in range(rows - 1):
        next_costs = [INF_COST] * columns
        for column, value in enumerate(grid[row]):
            base = costs[column] + value
            for target in range(columns):
                next_costs[target] = min(next_costs[target], base + moves[value][target])
        costs = next_costs
    return min(costs[column] + grid[-1][column] for column in range(columns))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: tuple[int, ...] | list[int]) -> None:
        key = tuple(values)
        cases[key] = oracle(list(key))

    for case in workload["cases"]:
        values = encode_grid_case(case)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
        add(values)

    # Exhaust every grid and small movement table for 1x2 and 2x1 shapes.
    for rows, columns in ((1, 2), (2, 1)):
        cells = rows * columns
        for grid_values in product(range(cells), repeat=cells):
            for move_values in product((1, 2, 3), repeat=cells * columns):
                add((rows, columns, *grid_values, *move_values))
    # Exercise all 2x2 cell permutations with uniform transition costs.
    for grid_values in permutations(range(4)):
        for move_value in (1, 2, 3):
            add((2, 2, *grid_values, *((move_value,) * 8)))

    rng = random.Random(20261015)
    for _ in range(512):
        rows, columns = rng.randint(1, 8), rng.randint(1, 8)
        cells = rows * columns
        grid_values = tuple(rng.randrange(cells) for _ in range(cells))
        move_values = tuple(rng.randint(1, 100) for _ in range(cells * columns))
        add((rows, columns, *grid_values, *move_values))

    rows = columns = MAX_DIMENSION
    cells = rows * columns
    add((rows, columns, *(index % cells for index in range(cells)),
         *(1 + (index * 37) % 100 for index in range(cells * columns))))
    for values in ((0, 1), (1, 0), (33, 1), (1, 1, 0), (1, 1, 1, 1),
                   (1, 1, 2, 1), (1, 1, 0, 0, 0)):
        add(values)

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_grid_case(case)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/minimum_path_cost_in_grid")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/m/minimum_path_cost_in_grid/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "oracle-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
