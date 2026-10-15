#!/usr/bin/env python3
"""Verify the packed-board Word Search implementations."""

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

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "word_search"
MAX_ROWS = 6
MAX_COLUMNS = 6
MAX_WORD_LENGTH = 15


def encode(board: list[str], word: str) -> list[int]:
    rows = len(board)
    columns = len(board[0]) if rows else 0
    return [rows, columns, *(ord(character) for row in board for character in row),
            len(word), *(ord(character) for character in word)]


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 5 or len(values) > 100
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    rows, columns = values[0], values[1]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return -1
    cells = rows * columns
    word_length_index = 2 + cells
    if len(values) <= word_length_index:
        return -1
    word_length = values[word_length_index]
    if not 1 <= word_length <= MAX_WORD_LENGTH or len(values) != word_length_index + 1 + word_length:
        return -1
    board = values[2:word_length_index]
    word = values[word_length_index + 1:]
    is_letter = lambda code: 65 <= code <= 90 or 97 <= code <= 122
    if any(not is_letter(code) for code in [*board, *word]):
        return -1
    if word_length > cells:
        return 0

    visited: set[int] = set()

    def visit(position: int, word_index: int) -> bool:
        if position in visited or board[position] != word[word_index]:
            return False
        visited.add(position)
        if word_index + 1 == word_length:
            visited.remove(position)
            return True
        row, column = divmod(position, columns)
        neighbors = []
        if row > 0:
            neighbors.append(position - columns)
        if row + 1 < rows:
            neighbors.append(position + columns)
        if column > 0:
            neighbors.append(position - 1)
        if column + 1 < columns:
            neighbors.append(position + 1)
        found = any(visit(next_position, word_index + 1) for next_position in neighbors)
        visited.remove(position)
        return found

    return int(any(visit(position, 0) for position in range(cells)))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: list[int]) -> None:
        cases[tuple(values)] = oracle(values)

    for rows, columns in ((1, 1), (1, 2), (2, 2), (2, 3)):
        for board in product((ord("A"), ord("B")), repeat=rows * columns):
            for length in range(1, min(5, rows * columns + 1) + 1):
                for word in product((ord("A"), ord("B")), repeat=length):
                    add([rows, columns, *board, length, *word])

    rng = random.Random(20261015)
    for rows, columns in ((1, 3), (2, 2), (3, 3), (4, 4), (6, 6)):
        for _ in range(16):
            board = [[rng.choice("ABCD") for _ in range(columns)] for _ in range(rows)]
            word_length = rng.randint(1, min(MAX_WORD_LENGTH, rows * columns))
            # Half the samples come from a simple path so positive cases are covered too.
            if rng.randrange(2) == 0:
                start = rng.randrange(rows * columns)
                path = [start]
                while len(path) < word_length:
                    row, column = divmod(path[-1], columns)
                    neighbors = []
                    if row > 0: neighbors.append(path[-1] - columns)
                    if row + 1 < rows: neighbors.append(path[-1] + columns)
                    if column > 0: neighbors.append(path[-1] - 1)
                    if column + 1 < columns: neighbors.append(path[-1] + 1)
                    choices = [position for position in neighbors if position not in path]
                    if not choices:
                        break
                    path.append(rng.choice(choices))
                word = "".join(board[position // columns][position % columns] for position in path)
            else:
                word = "".join(rng.choice("ABCD") for _ in range(word_length))
            add(encode(["".join(row) for row in board], word))

    for case in workload["cases"]:
        values = case["input_values"]
        expected = oracle(values)
        if case["expected_result"] != expected:
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values)

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
    if checked.returncode:
        raise RuntimeError(f"array scalar ABI check failed: {checked.stderr}")
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
        values = case["input_values"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build" / ALGORITHM)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/w/word_search/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
