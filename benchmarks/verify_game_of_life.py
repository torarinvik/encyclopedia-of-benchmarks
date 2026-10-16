#!/usr/bin/env python3
"""Verify Game of Life ports with an independent neighbor-accumulation oracle."""

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
from run_i64_array_bytes_output import expected_output

ALGORITHM = "game_of_life"
MAX_SIDE = 32
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    if (not values or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                           for value in values)):
        return -1, b""
    side = values[0]
    if (not 0 <= side <= MAX_SIDE or len(values) != 1 + side * side
            or any(cell not in (0, 1) for cell in values[1:])):
        return -1, b""
    neighbors = [0] * (side * side)
    for row in range(side):
        for column in range(side):
            if values[1 + row * side + column] == 0:
                continue
            for neighbor_row in range(max(0, row - 1), min(side, row + 2)):
                for neighbor_column in range(max(0, column - 1), min(side, column + 2)):
                    if (neighbor_row, neighbor_column) != (row, column):
                        neighbors[neighbor_row * side + neighbor_column] += 1
    output = bytes(
        int((values[1 + index] == 1 and neighbors[index] in (2, 3))
            or (values[1 + index] == 0 and neighbors[index] == 3))
        for index in range(side * side)
    )
    return len(output), output


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...] | list[int]) -> None:
        packed = tuple(values)
        result = oracle(packed)
        runner_result = expected_output(list(packed), ALGORITHM)
        if result != runner_result:
            raise ValueError(f"independent and recorder oracles disagree for input {packed[:8]}")
        cases[packed] = result

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = oracle(values)
        if (case["expected_result"] != result
                or case["expected_output_hex"] != output.hex()):
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
        add(values)

    for side in range(4):
        for cells in product((0, 1), repeat=side * side):
            add((side, *cells))

    rng = random.Random(20261015)
    for _ in range(256):
        side = rng.randrange(4, MAX_SIDE + 1)
        add((side, *(rng.randrange(2) for _ in range(side * side))))

    invalid = [(), (-1,), (MAX_SIDE + 1,), (1,), (2, 0, 1, 1),
               (1, -1), (1, 2), (0, 0), tuple([1] + [0] * (MAX_SIDE * MAX_SIDE + 1))]
    for values in invalid:
        add(values)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{suffix} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS,
                        default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/game_of_life")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language choices must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/g/game_of_life/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr,
                      flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle boards", flush=True)
    report = {"algorithm": ALGORITHM,
              "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / f"{ALGORITHM}-verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return int(bool(failures) or len(results) != len(args.languages))


if __name__ == "__main__":
    raise SystemExit(main())
