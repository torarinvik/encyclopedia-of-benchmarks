#!/usr/bin/env python3
"""Verify lazy-heap Dijkstra ports against two independent bounded references."""

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

from build_abi import ROOT, build, sha256_file
from d.dijkstra_lazy_heap.independent_oracle import expected_result as independent
from d.dijkstra_lazy_heap.primary_oracle import I64_MAX, expected_result as primary
from run_shortest_path import encode_case


def make_case(identifier: str, vertices: int, edges: list, source: int = 0) -> dict:
    result = primary(vertices, edges, source)
    if independent(vertices, edges, source) != result:
        raise ValueError(f"lazy-heap and Bellman–Ford references disagree: {identifier}")
    return {"id": identifier, "vertices": vertices, "source": source, "edges": edges,
            "expected_status": result[0], "expected_distances": result[1]}


def corpus(workload: dict) -> tuple[str, int]:
    cases = list(workload["cases"])
    for case in cases:
        actual = primary(case["vertices"], case["edges"], case["source"])
        if actual != (case["expected_status"], case["expected_distances"]):
            raise ValueError(f"published workload differs from lazy-heap oracle: {case['id']}")
        if independent(case["vertices"], case["edges"], case["source"]) != actual:
            raise ValueError(f"published workload differs from Bellman–Ford: {case['id']}")

    # Every directed edge choice on a two-vertex graph, including loops,
    # zero edges, INT64_MAX weights, and absent arcs.
    positions = [(origin, destination) for origin in range(2) for destination in range(2)]
    choices = (None, 0, 3, I64_MAX)
    for graph_index, selection in enumerate(itertools.product(choices, repeat=len(positions))):
        edges = [[origin, destination, weight]
                 for (origin, destination), weight in zip(positions, selection)
                 if weight is not None]
        for source in range(2):
            cases.append(make_case(f"exhaustive_{graph_index}_{source}", 2, edges, source))

    rng = random.Random(20261116)
    weights = [0, 0, 1, 2, 7, I64_MAX, I64_MAX - 1]
    for index in range(256):
        vertices = rng.randrange(1, 11)
        edges = [[rng.randrange(vertices), rng.randrange(vertices), rng.choice(weights)]
                 for _ in range(rng.randrange(3 * vertices + 1))]
        source = rng.randrange(vertices)
        cases.append(make_case(f"random_{index}", vertices, edges, source))
        cases.append(make_case(f"reversed_{index}", vertices, list(reversed(edges)), source))

    cases.extend([
        make_case("negative_weight", 2, [[0, 1, -1]]),
        make_case("unreachable_negative_weight", 3, [[1, 2, -1]]),
        make_case("bad_endpoint_precedes_negative_weight", 2, [[0, 2, -1]]),
        make_case("bad_source", 1, [], 1),
        make_case("bad_empty_source", 0, [], 1),
        make_case("too_many_vertices", 65, []),
        make_case("too_many_edges", 1, [[0, 0, 0] for _ in range(257)]),
        make_case("maximum_size_t_source", 1, [], 2 ** (8 * struct.calcsize("P")) - 1),
    ])
    return "".join(encode_case(case) for case in cases), len(cases)


def verify(language: str, directory: Path, compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build("dijkstra_lazy_heap", language, directory, family="shortest_path",
                     compiler=compiler)
    executable = manifest["binaries"]["shortest_path_runner"]["path"]
    checked = subprocess.run([executable, "--check"], input=data, capture_output=True,
                             text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"shortest-path ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("shortest-path checker did not consume the complete corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_shortest_path.py"),
        "--build-manifest", str(directory / "build.json"),
        "--workload", str(ROOT / "benchmarks/d/dijkstra_lazy_heap/workload.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"shortest-path workload recording failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("workload recorder returned the wrong record count")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != "dijkstra_lazy_heap"
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["edge_count"] != len(case["edges"])
                or record["workload"]["input_length"] != case["vertices"]
                or record["workload"]["source_vertex"] != case["source"]
                or record["measurement"]["observed_result"] != case["expected_status"]
                or record["measurement"]["observed_distances"] != case["expected_distances"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded output or provenance mismatch: {case['id']}")
    return {"language": language, "status": "passed", "oracle_graphs": case_count,
            "source_sha256": manifest["source_sha256"], "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+",
                        default=["c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"])
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--mojo-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/dijkstra_lazy_heap")
    args = parser.parse_args()
    supported = {"c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig"}
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language names must be unique")
    if any(language not in supported for language in args.languages):
        parser.error("unknown language")

    workload_path = ROOT / "benchmarks/d/dijkstra_lazy_heap/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != "dijkstra_lazy_heap" or workload.get("abi") != "shortest_path":
        parser.error("workload identity or ABI is incorrect")
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "dijkstra-lazy-heap-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    def compiler_for(language: str) -> str | None:
        if language == "elisa":
            return args.elisa_compiler
        if language == "mojo":
            return args.mojo_compiler
        return None

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / "d/dijkstra_lazy_heap" / language,
                                compiler_for(language), data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
                print(f"PASS dijkstra_lazy_heap/{language}: {case_count} oracle graphs, "
                      f"{result['workload_records']} workload records", flush=True)
            except Exception as error:
                result = {"language": language, "status": "failed", "error": str(error)}
                print(f"FAIL dijkstra_lazy_heap/{language}: {error}", file=sys.stderr, flush=True)
            results.append(result)
    report = {"checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "algorithm": "dijkstra_lazy_heap",
              "host": {"os": platform.system(), "architecture": platform.machine()},
              "all_passed": all(result["status"] == "passed" for result in results),
              "corpus_path": str(corpus_path),
              "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_shortest_path.py"),
              "harness_source_sha256": sha256_file(ROOT / "benchmarks/harness/shortest_path_runner.c"),
              "workload_sha256": sha256_file(workload_path),
              "results": sorted(results, key=lambda result: result["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
