#!/usr/bin/env python3
"""Verify BFS/DFS ports against exhaustive and randomized directed graphs."""

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
from run_i64_array_bytes_output import expected_output, fnv1a


def encode(values: list[int], count: int, output: bytes) -> str:
    values_text = "" if not values else " " + " ".join(map(str, values))
    encoded = output.hex() if output else "-"
    return f"{len(values)} {count} {len(output)}{values_text} {encoded}\n"


def corpus(algorithm: str, workload: dict) -> tuple[str, int]:
    records: list[tuple[list[int], int, bytes]] = []
    for case in workload["cases"]:
        values = case["input_values"]
        count, output = expected_output(values, algorithm)
        if case["expected_result"] != count or case["expected_order"] != list(output):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        records.append((values, count, output))

    # Exhaust every directed simple graph through three vertices and every valid root.
    for vertices in range(4):
        edge_positions = [(origin, destination)
                          for origin in range(vertices) for destination in range(vertices)]
        for graph_mask in range(1 << len(edge_positions)):
            edges = [edge for bit, edge in enumerate(edge_positions)
                     if graph_mask & (1 << bit)]
            if vertices == 0:
                values = [0, -1]
                records.append((values, *expected_output(values, algorithm)))
                continue
            for start in range(vertices):
                values = [vertices, start]
                for edge in edges:
                    values.extend(edge)
                records.append((values, *expected_output(values, algorithm)))

    rng = random.Random(20261014)
    for _ in range(512):
        vertices = rng.randrange(0, 65)
        if vertices == 0:
            values = [0, -1]
        else:
            values = [vertices, rng.randrange(vertices)]
            for _ in range(rng.randrange(0, 33)):
                values.extend((rng.randrange(vertices), rng.randrange(vertices)))
        records.append((values, *expected_output(values, algorithm)))

    malformed = [
        [],
        [1],
        [0, 0],
        [0, -1, 0, 0],
        [-1, 0],
        [65, 0],
        [3, 3],
        [3, -1],
        [2, 0, 1],
        [2, 0, 0, 2],
        [2, 0, -1, 1],
    ]
    for values in malformed:
        records.append((values, *expected_output(values, algorithm)))

    # Check that an otherwise valid nonempty traversal rejects an empty output buffer.
    values = [3, 0, 0, 1, 1, 2]
    records.append((values, -2, b""))

    lines = [f"{len(records)}\n"]
    lines.extend(encode(values, count, output) for values, count, output in records)
    return "".join(lines), len(records)


def verify(algorithm: str, language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(algorithm, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"graph-traversal C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete graph corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    output_records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(output_records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected record count")
    for case, record in zip(workload["cases"], output_records):
        values = case["input_values"]
        expected_count, expected_order = expected_output(values, algorithm)
        if (record["algorithm"] != algorithm
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_count
                or record["measurement"]["observed_result"] != expected_count
                or record["measurement"]["result_checksum"] != fnv1a(expected_order)
                or case["expected_order"] != list(expected_order)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded traversal/provenance mismatch: {case['id']}")
    return {"algorithm": algorithm, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(output_records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--algorithm", required=True,
                        choices=("breadth_first_search", "depth_first_search"))
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    algorithm = args.algorithm
    workload_path = ROOT / "benchmarks" / algorithm[0] / algorithm / "workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(algorithm, workload)
    directory = (args.build_dir or ROOT / "build/i64_array_bytes_output" / algorithm).resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{algorithm}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, algorithm, language, directory / language,
                            args.elisa_compiler, data, case_count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": algorithm, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {algorithm}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {algorithm}/{language}: {case_count} graph cases, "
                      f"{result['workload_records']} workload records", flush=True)
            results.append(result)

    report = {
        "algorithm": algorithm,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(args.languages)
                      and all(result["status"] == "passed" for result in results),
        "corpus_sha256": sha256_file(corpus_path),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "recorder_source_sha256": sha256_file(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "workload_sha256": sha256_file(workload_path),
        "results": sorted(results, key=lambda item: item["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
