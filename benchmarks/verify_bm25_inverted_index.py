#!/usr/bin/env python3
"""Verify BM25 inverted-index ports against a direct scoring oracle."""

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

from bm25_inverted_index_oracle import (
    MAX_DOCUMENTS,
    MAX_OUTPUT_LENGTH,
    MAX_TERMS_PER_DOCUMENT,
    expected_output,
)
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "bm25_inverted_index"
WORKLOAD_PATH = ROOT / "benchmarks/b/bm25_inverted_index/workload.json"


def pack(documents: list[tuple[int, list[int]]], query: int) -> tuple[int, ...]:
    values = [len(documents)]
    for document_id, terms in documents:
        values.extend((document_id, len(terms), *terms))
    values.append(query)
    return tuple(values)


def corpus(workload: dict) -> tuple[str, int, dict[tuple[tuple[int, ...], int], tuple[int, bytes]]]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

    def include(values: tuple[int, ...], capacity: int = MAX_OUTPUT_LENGTH,
                declared: tuple[int, bytes] | None = None) -> None:
        required_count, required_output = expected_output(list(values))
        if declared is not None and (required_count != declared[0]
                                     or required_output != declared[1]):
            raise ValueError("published workload differs from the BM25 oracle")
        if capacity < 0 or capacity > MAX_OUTPUT_LENGTH:
            raise ValueError("invalid BM25 output capacity")
        actual = (-2, b"") if required_count >= 0 and capacity < len(required_output) else (
            required_count, required_output)
        cases[(values, capacity)] = actual

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        required = expected_output(list(values))
        capacity = case.get("workspace_bytes", len(required[1]))
        expected = (-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required
        if (case.get("expected_result") != expected[0]
                or case.get("expected_output_hex", "") != expected[1].hex()):
            raise ValueError(f"workload output disagrees with oracle: {case['id']}")
        include(values, capacity, required)

    sequences = [tuple(items) for length in range(4)
                 for items in product((1, 2), repeat=length)]
    for document_count in range(4):
        for documents in product(sequences, repeat=document_count):
            rows = [(document_id, list(terms)) for document_id, terms in enumerate(documents)]
            for query in (1, 2):
                include(pack(rows, query))

    rng = random.Random(20261015)
    for _ in range(512):
        document_count = rng.randrange(MAX_DOCUMENTS + 1)
        ids = rng.sample(range(256), document_count)
        rows = [(document_id, [rng.randrange(1, 17)
                               for _ in range(rng.randrange(MAX_TERMS_PER_DOCUMENT + 1))])
                for document_id in ids]
        include(pack(rows, rng.randrange(1, 17)))

    for invalid in ((), (0,), (-1, 7), (33, 7), (0, 0),
                    (1, 5, 1, 7), (1, 5, 1, 7, 0),
                    (1, -1, 1, 7, 7), (1, 256, 1, 7, 7),
                    (2, 5, 1, 7, 5, 1, 7, 7), (1, 5, -1, 7),
                    (1, 5, 1, 0, 7), (1, 5, 1, 256, 7),
                    (1, 5, 65, *([7] * 65), 7), (0, 256)):
        include(tuple(invalid))

    for values in (tuple(workload["cases"][2]["input_values"]),
                   pack([(5, [7, 1]), (4, [7, 2, 3]), (3, [7, 4, 5, 6])], 7),
                   pack([(6, [3, 3]), (2, [3, 4, 5])], 3)):
        result, output = expected_output(list(values))
        for capacity in range(len(output) + 1):
            include(values, capacity, (result, output))

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for (values, capacity), (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)} {capacity}{values_text} "
                     f"{output.hex() if output else '-'}\n")
    return "".join(lines), len(records), cases


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int,
           cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]], workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"BM25 ABI check failed for {language} (exit {checked.returncode}): "
                           f"{checked.stdout}\n{checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete BM25 corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"BM25 workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of BM25 workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        required_count, required_output = expected_output(list(values))
        capacity = case.get("workspace_bytes", len(required_output))
        expected = (-2, b"") if required_count >= 0 and capacity < len(required_output) else (
            required_count, required_output)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["expected_result"] != expected[0]
                or record["measurement"]["observed_result"] != expected[0]
                or record["measurement"]["result_checksum"] != fnv1a(expected[1])):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/bm25_inverted_index")
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages):
        parser.error("jobs must be between 1 and the selected language count")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    checker_input, case_count, cases = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language, args.build_dir / language,
                            args.elisa_compiler, checker_input, case_count, cases, workload): language
            for language in args.languages
        }
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda record: record["language"])
    report = {"schema_version": 1, "algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": {"system": platform.system(), "release": platform.release(),
                           "machine": platform.machine(), "python": platform.python_version()},
              "oracle_cases_per_language": case_count,
              "workload_records_per_language": len(workload["cases"]), "languages": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "oracle_cases_per_language": case_count,
                      "languages": [record["language"] for record in results],
                      "report": str(report_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
