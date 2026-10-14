#!/usr/bin/env python3
"""Check Dijkstra ports through the C ABI against a heap-based oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import heapq
import itertools
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import ROOT, build, sha256_file
from run_shortest_path import I64_MAX, I64_MIN, encode_case


def oracle(vertices: int, edges: list, source: int) -> tuple[int, list | None]:
    if vertices == 0:
        return (0, []) if source == 0 and not edges else (-3, None)
    if not 0 <= source < vertices:
        return -3, None
    for origin, destination, weight in edges:
        if not 0 <= origin < vertices or not 0 <= destination < vertices:
            return -3, None
        if weight < 0:
            return -4, None
    adjacency = [[] for _ in range(vertices)]
    for origin, destination, weight in edges:
        adjacency[origin].append((destination, weight))
    distances = [None] * vertices
    distances[source] = 0
    pending = [(0, source)]
    settled = set()
    while pending:
        distance, origin = heapq.heappop(pending)
        if origin in settled or distance != distances[origin]:
            continue
        settled.add(origin)
        for destination, weight in adjacency[origin]:
            candidate = distance + weight
            if candidate > I64_MAX:
                return -2, None
            if destination not in settled and (distances[destination] is None or candidate < distances[destination]):
                distances[destination] = candidate
                heapq.heappush(pending, (candidate, destination))
    return 0, distances


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
        positions = [(u, v) for u in range(vertices) for v in range(vertices) if u != v]
        for graph_index, choices in enumerate(itertools.product((None, 0, 4, I64_MAX), repeat=len(positions))):
            edges = [[u, v, weight] for (u, v), weight in zip(positions, choices) if weight is not None]
            for source in range(vertices):
                cases.append(make_case(f"exhaustive_{vertices}_{graph_index}_{source}", vertices, edges, source))
    rng = random.Random(20261014)
    weights = [0, 0, 1, 2, 7, I64_MAX, I64_MAX - 1]
    for index in range(384):
        vertices = rng.randrange(1, 10)
        edges = [[rng.randrange(vertices), rng.randrange(vertices), rng.choice(weights)]
                 for _ in range(rng.randrange(2 * vertices * vertices + 1))]
        source = rng.randrange(vertices)
        cases.append(make_case(f"random_{index}", vertices, edges, source))
        cases.append(make_case(f"reversed_{index}", vertices, list(reversed(edges)), source))
    cases.append(make_case("negative_edge", 2, [[0, 1, -1]]))
    cases.append(make_case("unreachable_negative_edge", 3, [[1, 2, -1]]))
    cases.append(make_case("invalid_negative_edge_endpoint", 2, [[0, 4, -1]]))
    cases.append(make_case("maximum_size_t_source", 1, [], 2 ** (8 * struct.calcsize("P")) - 1))
    return "".join(encode_case(case) for case in cases), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None, data: str,
           case_count: int, workload: dict) -> dict:
    manifest = build("dijkstra", language, directory, family="shortest_path",
                     compiler=elisa_compiler if language == "elisa" else None)
    executable = manifest["binaries"]["shortest_path_runner"]["path"]
    checked = subprocess.run([executable, "--check"], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"graph C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("graph checker did not consume the complete corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_shortest_path.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"graph workload/recording check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("graph recorder returned the wrong record count")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != "dijkstra" or record["implementation"]["language"] != language
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
    parser.add_argument("--languages", nargs="+", default=["c", "c3", "cpp", "elisa", "nim", "odin", "rust", "v", "zig"])
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/dijkstra")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    workload_path = ROOT / "benchmarks/d/dijkstra/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "dijkstra-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / "d/dijkstra" / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
                print(f"PASS dijkstra/{language}: {case_count} oracle graphs, "
                      f"{result['workload_records']} workload records", flush=True)
            except Exception as error:
                result = {"language": language, "status": "failed", "error": str(error)}
                print(f"FAIL dijkstra/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "algorithm": "dijkstra", "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": all(result["status"] == "passed" for result in results),
              "corpus_path": str(corpus_path), "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_shortest_path.py"),
              "harness_source_sha256": sha256_file(ROOT / "benchmarks/harness/shortest_path_runner.c"),
              "result_schema_sha256": sha256_file(ROOT / "benchmarks/results.schema.json"),
              "workload_sha256": sha256_file(workload_path), "results": sorted(results, key=lambda r: r["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
