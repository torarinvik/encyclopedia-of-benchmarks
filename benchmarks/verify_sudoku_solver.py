#!/usr/bin/env python3
"""Verify Sudoku ports against an independent minimum-remaining-values oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "sudoku_solver"
BOARD_CELLS = 81
OUTPUT_BYTES = BOARD_CELLS * 4


def unique_solution(values: list[int]) -> list[int] | None:
    if (not isinstance(values, list) or len(values) != BOARD_CELLS
            or any(type(value) is not int or not 0 <= value <= 9 for value in values)):
        return None
    board = list(values)
    rows = [set() for _ in range(9)]
    columns = [set() for _ in range(9)]
    boxes = [set() for _ in range(9)]
    for position, digit in enumerate(board):
        if digit == 0:
            continue
        row, column = divmod(position, 9)
        box = (row // 3) * 3 + column // 3
        if digit in rows[row] or digit in columns[column] or digit in boxes[box]:
            return None
        rows[row].add(digit)
        columns[column].add(digit)
        boxes[box].add(digit)

    solutions: list[list[int]] = []

    def search() -> None:
        if len(solutions) >= 2:
            return
        best_position = -1
        best_candidates: set[int] | None = None
        for position, digit in enumerate(board):
            if digit != 0:
                continue
            row, column = divmod(position, 9)
            box = (row // 3) * 3 + column // 3
            candidates = set(range(1, 10)) - rows[row] - columns[column] - boxes[box]
            if not candidates:
                return
            if best_candidates is None or len(candidates) < len(best_candidates):
                best_position, best_candidates = position, candidates
                if len(candidates) == 1:
                    break
        if best_position < 0:
            solutions.append(list(board))
            return
        row, column = divmod(best_position, 9)
        box = (row // 3) * 3 + column // 3
        for digit in sorted(best_candidates):
            board[best_position] = digit
            rows[row].add(digit)
            columns[column].add(digit)
            boxes[box].add(digit)
            search()
            board[best_position] = 0
            rows[row].remove(digit)
            columns[column].remove(digit)
            boxes[box].remove(digit)
            if len(solutions) >= 2:
                return

    search()
    return solutions[0] if len(solutions) == 1 else None


def oracle(values: list[int]) -> tuple[int, bytes]:
    solution = unique_solution(values)
    if solution is None:
        return -1, b""
    return BOARD_CELLS, struct.pack("<81i", *solution)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: list[int]) -> None:
        cases[tuple(values)] = oracle(values)

    for case in workload["cases"]:
        expected_count, expected_bytes = oracle(case["input_values"])
        source_count, source_bytes = expected_output(case["input_values"], ALGORITHM)
        if (expected_count != case["expected_result"]
                or expected_bytes.hex() != case.get("expected_output_hex", "")
                or (source_count, source_bytes) != (expected_count, expected_bytes)):
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(case["input_values"])

    rng = random.Random(20261015)
    solved = next(case["input_values"] for case in workload["cases"]
                  if case["id"] == "already_solved")
    accepted = 0
    for attempt in range(500):
        solution = list(solved)
        digit_map = list(range(1, 10))
        rng.shuffle(digit_map)
        solution = [0 if value == 0 else digit_map[value - 1] for value in solution]
        puzzle = list(solution)
        blank_count = rng.randint(1, 28)
        for position in rng.sample(range(BOARD_CELLS), blank_count):
            puzzle[position] = 0
        if unique_solution(puzzle) is None:
            continue
        add(puzzle)
        accepted += 1
        if accepted == 96:
            break
    if accepted < 48:
        raise RuntimeError(f"only generated {accepted} additional uniquely solvable boards")

    lines = [f"{len(cases) + 1}\n"]
    for values, (expected_count, output) in cases.items():
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {expected_count} {len(output)}{values_text} {encoded}\n")
    capacity_case = next(case["input_values"] for case in workload["cases"]
                         if case["id"] == "classic_puzzle")
    lines.append(f"{len(capacity_case)} -2 0 "
                 + " ".join(map(str, capacity_case)) + " -\n")
    return "".join(lines), len(cases) + 1


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/sudoku_solver")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/s/sudoku_solver/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "sudoku-solver-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
