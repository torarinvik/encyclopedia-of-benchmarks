#!/usr/bin/env python3
"""Check isolated-node ports against exhaustive and generated directed graphs."""

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


def corpus(workload: dict) -> tuple[str, int]:
    records: list[tuple[list[int], int, bytes]] = []
    for case in workload["cases"]:
        values = case["input_values"]
        count, output = expected_output(values, "find_isolated_nodes")
        if case.get("workspace_bytes", len(output)) < len(output):
            count, output = -2, b""
        expected_vertices = list(output)
        if (case["expected_result"] != count
                or case["expected_vertices"] != expected_vertices
                or case["expected_output_hex"] != output.hex()):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        records.append((values, count, output))

    # Exhaust every simple directed graph through three vertices.
    for vertices in range(4):
        edge_positions = [(origin, destination)
                          for origin in range(vertices) for destination in range(vertices)]
        for graph_mask in range(1 << len(edge_positions)):
            values = [vertices]
            for bit, edge in enumerate(edge_positions):
                if graph_mask & (1 << bit):
                    values.extend(edge)
            records.append((values, *expected_output(values, "find_isolated_nodes")))

    rng = random.Random(20261015)
    for _ in range(512):
        vertices = rng.randrange(0, 65)
        values = [vertices]
        if vertices:
            for _ in range(rng.randrange(0, 33)):
                values.extend((rng.randrange(vertices), rng.randrange(vertices)))
        records.append((values, *expected_output(values, "find_isolated_nodes")))

    malformed = [[], [-1], [65], [2, 0], [2, -1, 1], [2, 0, 2]]
    for values in malformed:
        records.append((values, *expected_output(values, "find_isolated_nodes")))

    lines = [f"{len(records)}\n"]
    lines.extend(encode(values, count, output) for values, count, output in records)
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict, checker_only: bool) -> dict:
    manifest = build("find_isolated_nodes", language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"isolated-node C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete graph corpus")

    result = {"algorithm": "find_isolated_nodes", "language": language, "status": "passed",
              "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
              "build_manifest": str(directory / "build.json"),
              "build_manifest_sha256": sha256_file(directory / "build.json")}
    if checker_only:
        return result

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
        expected_count, expected_output_bytes = expected_output(values, "find_isolated_nodes")
        capacity = case.get("workspace_bytes", len(expected_output_bytes))
        expected_result = -2 if capacity < len(expected_output_bytes) else expected_count
        expected_bytes = b"" if expected_result < 0 else expected_output_bytes
        if (record["algorithm"] != "find_isolated_nodes"
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected_result
                or record["measurement"]["observed_result"] != expected_result
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded output/provenance mismatch: {case['id']}")
    result.update({"workload_records": len(output_records),
                   "recorder_output": str(output_path),
                   "recorder_output_sha256": sha256_file(output_path)})
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    parser.add_argument("--checker-only", action="store_true")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and languages must be unique")

    workload_path = ROOT / "benchmarks/f/find_isolated_nodes/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = (args.build_dir or ROOT / "build/i64_array_bytes_output/find_isolated_nodes").resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "find_isolated_nodes-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload, args.checker_only): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": "find_isolated_nodes", "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL find_isolated_nodes/{language}: {error}", file=sys.stderr, flush=True)
            else:
                suffix = "checker-only" if args.checker_only else f"{result['workload_records']} workload records"
                print(f"PASS find_isolated_nodes/{language}: {case_count} graph cases, {suffix}", flush=True)
            results.append(result)

    report = {
        "algorithm": "find_isolated_nodes",
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
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
