#!/usr/bin/env python3
"""Verify bounded Floyd-Warshall implementations through the shortest-path C ABI."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_shortest_path import I64_MIN, I64_MAX, encode_case

ALGORITHM = "floyd_warshall"
MAX_VERTICES = 64


def oracle(vertices: int, edges: list, source: int) -> tuple[int, list | None]:
    if vertices == 0:
        return (0, []) if source == 0 and not edges else (-3, None)
    if vertices > MAX_VERTICES or not 0 <= source < vertices:
        return -3, None
    if any(not 0 <= u < vertices or not 0 <= v < vertices for u, v, _ in edges):
        return -3, None
    matrix: list[list[int | None]] = [[None] * vertices for _ in range(vertices)]
    for vertex in range(vertices):
        matrix[vertex][vertex] = 0
    for origin, destination, weight in edges:
        previous = matrix[origin][destination]
        matrix[origin][destination] = weight if previous is None else min(previous, weight)
    for middle in range(vertices):
        for origin in range(vertices):
            left = matrix[origin][middle]
            if left is None:
                continue
            for destination in range(vertices):
                right = matrix[middle][destination]
                if right is None:
                    continue
                candidate = left + right
                if not I64_MIN <= candidate <= I64_MAX:
                    return -2, None
                previous = matrix[origin][destination]
                if previous is None or candidate < previous:
                    matrix[origin][destination] = candidate
    if any(matrix[source][vertex] is not None and matrix[vertex][vertex] is not None
           and matrix[vertex][vertex] < 0 for vertex in range(vertices)):
        return -1, None
    return 0, matrix[source]


def make_case(identifier: str, vertices: int, edges: list, source: int = 0) -> dict:
    status, distances = oracle(vertices, edges, source)
    return {"id": identifier, "vertices": vertices, "source": source, "edges": edges,
            "expected_status": status, "expected_distances": distances}


def corpus(workload: dict) -> tuple[str, int]:
    cases = list(workload["cases"])
    for case in cases:
        if oracle(case["vertices"], case["edges"], case["source"]) != (
                case["expected_status"], case["expected_distances"]):
            raise ValueError(f"published workload disagrees with the oracle: {case['id']}")
    for vertices in (2, 3):
        positions = [(u, v) for u in range(vertices) for v in range(vertices)
                     if vertices == 2 or u != v]
        for graph_index, choices in enumerate(itertools.product((None, -2, 0, 3), repeat=len(positions))):
            edges = [[u, v, weight] for (u, v), weight in zip(positions, choices) if weight is not None]
            for source in range(vertices):
                cases.append(make_case(f"exhaustive_{vertices}_{graph_index}_{source}", vertices, edges, source))
    rng = random.Random(20261014)
    for index in range(256):
        vertices = rng.randrange(1, 10)
        edges = [[rng.randrange(vertices), rng.randrange(vertices), rng.randrange(-23, 32)]
                 for _ in range(rng.randrange(2 * vertices * vertices + 1))]
        source = rng.randrange(vertices)
        cases.append(make_case(f"random_{index}", vertices, edges, source))
        cases.append(make_case(f"reversed_{index}", vertices, list(reversed(edges)), source))
    cases.append(make_case("maximum_vertices_sparse_chain", MAX_VERTICES,
                           [[vertex, vertex + 1, 1] for vertex in range(MAX_VERTICES - 1)]))
    cases.append(make_case("size_t_maximum_source", 1, [], 2 ** (8 * struct.calcsize("P")) - 1))
    return "".join(encode_case(case) for case in cases), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory, family="shortest_path",
                     compiler=elisa_compiler if language == "elisa" else None)
    executable = manifest["binaries"]["shortest_path_runner"]["path"]
    checked = subprocess.run([executable, "--check"], input=data, capture_output=True,
                             text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"graph C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("graph checker did not consume the complete corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_shortest_path.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                              text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"graph workload/recording check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("graph recorder returned the wrong record count")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != ALGORITHM or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["edge_count"] != len(case["edges"])
                or record["workload"]["input_length"] != case["vertices"]
                or record["workload"]["source_vertex"] != case["source"]
                or record["measurement"]["observed_result"] != case["expected_status"]
                or record["measurement"]["observed_distances"] != case["expected_distances"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded graph output/provenance mismatch: {case['id']}")
    return {"language": language, "status": "passed", "oracle_graphs": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/shortest_path")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    workload_path = ROOT / "benchmarks/f/floyd_warshall/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "floyd_warshall-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language,
                                directory / "f/floyd_warshall" / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
                print(f"PASS {ALGORITHM}/{language}: {case_count} oracle graphs, "
                      f"{result['workload_records']} workload records", flush=True)
            except Exception as error:
                result = {"language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "algorithm": ALGORITHM,
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": all(result["status"] == "passed" for result in results),
              "corpus_path": str(corpus_path), "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_shortest_path.py"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "workload_sha256": sha256_file(workload_path),
              "results": sorted(results, key=lambda result: result["language"])}
    report_path = directory / "floyd_warshall-verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
