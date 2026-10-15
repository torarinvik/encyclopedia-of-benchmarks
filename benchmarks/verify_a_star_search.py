#!/usr/bin/env python3
"""Verify the shared unit-cost A* path contract across all nine target ports."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "a_star_search"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: list[int]) -> None:
        cases[tuple(values)] = expected_output(values, ALGORITHM)

    for case in workload["cases"]:
        values = case["input_values"]
        expected = expected_output(values, ALGORITHM)
        if case["expected_result"] != expected[0]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(values)] = expected

    # Exhaust every directed three-vertex topology with zero heuristic.
    possible_edges = [(u, v) for u in range(3) for v in range(3) if u != v]
    for mask in range(1 << len(possible_edges)):
        edges = [edge for bit, edge in enumerate(possible_edges) if mask & (1 << bit)]
        values = [3, len(edges), 0, 2, 0, 0, 0]
        values.extend(value for edge in edges for value in edge)
        add(values)

    rng = random.Random(20261015)
    for _ in range(768):
        vertex_count = rng.randrange(1, 32)
        edges = [(u, v) for u in range(vertex_count) for v in range(vertex_count)
                 if u != v and rng.random() < min(0.18, 3 / vertex_count)]
        source, target = rng.randrange(vertex_count), rng.randrange(vertex_count)
        reverse = [[] for _ in range(vertex_count)]
        for origin, neighbor in edges:
            reverse[neighbor].append(origin)
        distance = [None] * vertex_count
        distance[target] = 0
        queue = [target]
        for vertex in queue:
            for predecessor in reverse[vertex]:
                if distance[predecessor] is None:
                    distance[predecessor] = distance[vertex] + 1
                    queue.append(predecessor)
        # floor(distance/2) is consistent on unit edges and remains admissible.
        heuristic = [value // 2 if value is not None else 0 for value in distance]
        values = [vertex_count, len(edges), source, target, *heuristic]
        values.extend(value for edge in edges for value in edge)
        add(values)

    invalid = [
        [], [0, 0, 0, 0, 0], [1, 0, 1, 0, 0],
        [2, 1, 0, 1, 0, 0, 0],  # truncated edge list
        [2, 1, 0, 1, 0, 0, 0, 0, 2],  # endpoint out of range
        [2, 0, 0, 1, 0, 1],  # nonzero heuristic at target
        [2, 0, 0, 1, 0, -1],  # negative heuristic
        [2, 1, 0, 1, 0, 0, 0, 1],  # inconsistent heuristic
        [257, 0, 0, 0, *([0] * 257)],
        [1, 4097, 0, 0, 0],
    ]
    long_chain = [32, 31, 0, 31, *([0] * 32)]
    long_chain.extend(value for edge in ((i, i + 1) for i in range(31)) for value in edge)
    invalid.append(long_chain)  # beyond the reviewed C++ depth bound
    for values in invalid:
        add(values)

    records = sorted(cases.items())
    lines = [str(len(records)) + "\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {count} {len(output)}{values_text} {output.hex() if output else '-'}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--workload", str(ROOT / "benchmarks/a/a_star_search/workload.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/a_star_search")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/a/a_star_search/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "a_star_search-corpus.txt").write_text(data, encoding="utf-8")
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
