#!/usr/bin/env python3
"""Verify indexed sparse-heap Prim ports against Kruskal and workload fixtures."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
from itertools import product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, OPTIONAL_EXTENSIONS, ROOT, build, sha256_file
from p.prim_sparse_heap.independent_oracle import expected_result as independent
from p.prim_sparse_heap.primary_oracle import MAX_EDGES, MAX_WEIGHT, expected_result as primary
from p.prim_sparse_heap.verify_workload import verify_workload

ALGORITHM = "prim_sparse_heap"
SUPPORTED = {**EXTENSIONS, **OPTIONAL_EXTENSIONS}


def packed_case(values: list[int] | tuple[int, ...], identifier: str) -> tuple[tuple[int, ...], int]:
    packed = tuple(values)
    expected = primary(packed)
    if independent(packed) != expected:
        raise ValueError(f"indexed Prim and Kruskal disagree: {identifier}")
    return packed, expected


def corpus(workload: dict) -> tuple[str, int]:
    issues = verify_workload(workload)
    if issues:
        raise ValueError("sparse Prim package is incomplete: " + "; ".join(issues))
    cases: dict[tuple[int, ...], int] = {}

    def include(values: list[int] | tuple[int, ...], identifier: str) -> None:
        packed, expected = packed_case(values, identifier)
        cases[packed] = expected

    # Exhaust every simple undirected graph through four vertices, with an
    # absent edge or each of two equal-cost states. Both algorithms see ties.
    for vertices in range(5):
        pairs = [(u, v) for u in range(vertices) for v in range(u + 1, vertices)]
        for graph_index, states in enumerate(product((-1, 0, 5), repeat=len(pairs))):
            edges = [(u, v, weight) for (u, v), weight in zip(pairs, states) if weight >= 0]
            include([vertices, len(edges), *(item for edge in edges for item in edge)],
                    f"exhaustive_{vertices}_{graph_index}")

    rng = random.Random(20261116)
    for index in range(512):
        vertices = rng.randrange(1, 65)
        edges = []
        for origin in range(vertices):
            for destination in range(origin + 1, vertices):
                if rng.random() < 0.045:
                    edges.append((origin, destination, rng.choice([0, 1, 2, 7, MAX_WEIGHT])))
        source_edges = list(edges)
        if vertices > 1 and index % 4 == 0:
            source_edges.append((0, 1, rng.choice([0, 1, 5, MAX_WEIGHT])))
            source_edges.append((0, 0, 0))
        include([vertices, len(source_edges), *(item for edge in source_edges for item in edge)],
                f"random_{index}")

    malformed = [[], [0], [0, 1, 0, 0, 1], [-1, 0], [65, 0], [2, -1],
                 [2, 1], [2, 0, 0], [2, 1, 0, 2, 1], [2, 1, -1, 0, 1],
                 [2, 1, 0, 1, -1], [2, 1, 0, 1, MAX_WEIGHT + 1],
                 [1, 1, 0, 0, 0], [0, 1], [1, MAX_EDGES + 1]]
    for index, values in enumerate(malformed):
        include(values, f"malformed_{index}")
    for case in workload["cases"]:
        include(case["input_values"], case["id"])

    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory, compiler=compiler,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"C ABI oracle check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("array-scalar checker did not consume the full corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"),
        "--workload", str(ROOT / "benchmarks/p/prim_sparse_heap/workload.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected record count")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        expected = primary(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records),
            "workload_sha256": sha256_file(ROOT / "benchmarks/p/prim_sparse_heap/workload.json"),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=SUPPORTED,
                        default=list(SUPPORTED))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--mojo-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/p/prim_sparse_heap")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")
    workload_path = ROOT / "benchmarks/p/prim_sparse_heap/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "prim-sparse-heap-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    def selected_compiler(language: str) -> str | None:
        if language == "elisa":
            return args.elisa_compiler
        if language == "mojo":
            return args.mojo_compiler
        return None

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                selected_compiler(language), data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} graph cases, "
                      f"{result['workload_records']} workload records", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "all_passed": len(results) == len(args.languages)
              and all(result["status"] == "passed" for result in results),
              "corpus_sha256": sha256_file(corpus_path),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "compiler_recipes_sha256": sha256_file(ROOT / "benchmarks/build_abi.py"),
              "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_i64_array_scalar.py"),
              "harness_source_sha256": sha256_file(ROOT / "benchmarks/harness/i64_array_scalar_runner.c"),
              "workload_sha256": sha256_file(workload_path),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
