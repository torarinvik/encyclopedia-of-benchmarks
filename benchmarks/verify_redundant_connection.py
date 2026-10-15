#!/usr/bin/env python3
"""Verify redundant-connection ports against a prefix-BFS graph oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations, permutations
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "redundant_connection"
MAX_VERTICES = 1000


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (len(values) < 6 or len(values) > 2 * MAX_VERTICES or len(values) % 2 != 0
            or any(type(value) is not int for value in values)):
        return -1, b""
    vertex_count = len(values) // 2
    if not 3 <= vertex_count <= MAX_VERTICES:
        return -1, b""
    edges = list(zip(values[::2], values[1::2]))
    if any(not 1 <= endpoint <= vertex_count for edge in edges for endpoint in edge):
        return -1, b""
    if any(left == right for left, right in edges):
        return -1, b""

    adjacency = [[] for _ in range(vertex_count + 1)]
    redundant: list[tuple[int, int]] = []
    for left, right in edges:
        seen = {left}
        queue = [left]
        for current in queue:
            for neighbor in adjacency[current]:
                if neighbor not in seen:
                    seen.add(neighbor)
                    queue.append(neighbor)
        if right in seen:
            redundant.append((left, right))
        adjacency[left].append(right)
        adjacency[right].append(left)
    if len(redundant) != 1:
        return -1, b""
    return 2, struct.pack("<ii", *redundant[0])


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    cases[()] = (-1, b"")
    # Exhaust every edge ordering for simple graphs with three or four vertices.
    for vertex_count in (3, 4):
        possible_edges = list(combinations(range(1, vertex_count + 1), 2))
        for edge_set in combinations(possible_edges, vertex_count):
            for ordered_edges in permutations(edge_set):
                values = tuple(endpoint for edge in ordered_edges for endpoint in edge)
                cases[values] = oracle(list(values))

    rng = random.Random(20261015)
    for _ in range(256):
        vertex_count = rng.randrange(3, 65)
        tree = [(node, rng.randrange(1, node)) for node in range(2, vertex_count + 1)]
        present = {tuple(sorted(edge)) for edge in tree}
        candidates = [(left, right) for left in range(1, vertex_count + 1)
                      for right in range(left + 1, vertex_count + 1)
                      if (left, right) not in present]
        tree.append(rng.choice(candidates))
        rng.shuffle(tree)
        values = tuple(endpoint for edge in tree for endpoint in edge)
        cases[values] = oracle(list(values))

    for values in (
        (1, 2),
        (1, 2, 2),
        (1, 2, 2, 2, 3, 3),
        (1, 2, 2, 3, 3, 1, 3, 4, 1, 4),
        (1, 2, 2, 3, 3, 4, 1, 5),
        (0,) * (2 * (MAX_VERTICES + 1)),
    ):
        cases[values] = oracle(list(values))

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result = oracle(list(values))
        if (case["expected_result"] != result[0]
                or case.get("expected_output_hex") != result[1].hex()
                or expected_output(list(values), ALGORITHM) != result):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = result

    records = sorted(cases.items())
    # A valid graph with zero output capacity must fail before writing.
    records.append(((1, 2, 1, 3, 2, 3), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (count, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {count} {len(output)}{values_text} {encoded}\n")
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
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"),
         "--samples", "1", "--warmups", "0", "--repetitions", "1",
         "--output", str(output)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
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
    return {
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "workload_records": len(records), "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output), "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/redundant_connection")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/r/redundant_connection/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

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
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
