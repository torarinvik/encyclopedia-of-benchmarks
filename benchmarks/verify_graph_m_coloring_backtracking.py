#!/usr/bin/env python3
"""Verify portable first-solution m-coloring ports against an independent DFS oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "graph_m_coloring_backtracking"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = expected_output(list(values), ALGORITHM)

    # Exhaust every simple graph through five vertices and each useful color count.
    for vertex_count in range(6):
        edges = list(combinations(range(vertex_count), 2))
        for mask in range(1 << len(edges)):
            matrix = [[0] * vertex_count for _ in range(vertex_count)]
            for edge_index, (left, right) in enumerate(edges):
                if (mask >> edge_index) & 1:
                    matrix[left][right] = matrix[right][left] = 1
            flattened = tuple(cell for row in matrix for cell in row)
            for max_colors in range(vertex_count + 2):
                add((vertex_count, max_colors, *flattened))

    rng = random.Random(20261016)
    for _ in range(512):
        vertex_count = rng.randrange(0, 13)
        matrix = [[0] * vertex_count for _ in range(vertex_count)]
        density = rng.random()
        for left in range(vertex_count):
            for right in range(left + 1, vertex_count):
                if rng.random() < density:
                    matrix[left][right] = matrix[right][left] = 1
        flattened = tuple(cell for row in matrix for cell in row)
        add((vertex_count, rng.randrange(0, 6), *flattened))

    for values in (
        (), (0,), (-1, 1), (13, 0), (1, -1, 0), (1, 13, 0),
        (1, 1), (1, 1, 2), (1, 1, 1), (2, 1, 0, 1, 0, 0),
    ):
        add(values)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        oracle = expected_output(list(values), ALGORITHM)
        if case["expected_result"] != oracle[0] or case["expected_output_hex"] != oracle[1].hex():
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = oracle

    records = sorted(cases.items())
    successful_nonempty = next(((values, result) for values, result in records
                                if result[0] > 0), None)
    if successful_nonempty is None:
        raise ValueError("corpus has no nonempty successful coloring")
    values, (count, _output) = successful_nonempty
    records.append((values, (-2, b"")))
    lines = [f"{len(records)}\n"]
    for input_values, (result, output) in records:
        values_text = "" if not input_values else " " + " ".join(map(str, input_values))
        lines.append(f"{len(input_values)} {result} {len(output)} 0{values_text} {output.hex() if output else '-'}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    result_records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(result_records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], result_records):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record provenance/result mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(result_records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output/graph_m_coloring_backtracking")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/g/graph_m_coloring_backtracking/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
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
