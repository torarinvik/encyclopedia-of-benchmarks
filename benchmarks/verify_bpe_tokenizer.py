#!/usr/bin/env python3
"""Verify byte-pair tokenizer ports against a first-seen-order oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from itertools import product
import json
from pathlib import Path
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from bpe_tokenizer_oracle import MAX_INPUT_LENGTH, MAX_MERGES, MAX_TEXT_BYTES
from run_i64_array_bytes_output import expected_output, fnv1a

ALGORITHM = "bpe_tokenizer"
WORKLOAD_PATH = ROOT / "benchmarks/b/bpe_tokenizer/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Independent implementation mirroring the pinned ordered-dictionary loop."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -2, b""
    merge_count, byte_count = values[:2]
    if (not 0 <= merge_count <= MAX_MERGES or not 0 <= byte_count <= MAX_TEXT_BYTES
            or len(values) != byte_count + 2
            or any(not 0 <= byte <= 255 for byte in values[2:])):
        return -2, b""

    ids = list(values[2:])
    for step in range(min(merge_count, len(ids) - 1)):
        pair_counts: dict[tuple[int, int], int] = {}
        position = 0
        while position + 1 < len(ids):
            pair = (ids[position], ids[position + 1])
            pair_counts[pair] = pair_counts.get(pair, 0) + 1
            position += 1
        if not pair_counts:
            break
        selected = next(iter(pair_counts))
        for pair, count in pair_counts.items():
            if count > pair_counts[selected]:
                selected = pair
        if pair_counts[selected] <= 1:
            break
        replaced = []
        position = 0
        while position < len(ids):
            if position + 1 < len(ids) and (ids[position], ids[position + 1]) == selected:
                replaced.append(256 + step)
                position += 2
            else:
                replaced.append(ids[position])
                position += 1
        ids = replaced
    encoded = bytearray()
    for token in ids:
        encoded.append(token & 255)
        encoded.append((token >> 8) & 255)
    return len(ids), bytes(encoded)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}
    default_capacity = workload["workspace"]["bytes"]

    def add(values: tuple[int, ...] | list[int], capacity: int = default_capacity) -> None:
        packed = tuple(values)
        required = oracle(packed)
        if expected_output(list(packed), ALGORITHM) != required:
            raise ValueError(f"independent and recorder oracles disagree for {packed[:12]}")
        result = (-2, b"") if required[0] >= 0 and capacity < len(required[1]) else required
        cases[(packed, capacity)] = result

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, payload = oracle(values)
        capacity = case.get("workspace_bytes", default_capacity)
        expected_result = -2 if result >= 0 and capacity < len(payload) else result
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != expected_result
                or case.get("expected_output_hex") != (payload.hex() if expected_result >= 0 else "")):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values, capacity)

    alphabet = (0, 1, 2)
    for length in range(7):
        for payload in product(alphabet, repeat=length):
            for merge_count in (0, 1, 2, 4, 8):
                add((merge_count, length, *payload))

    rng = random.Random(20261015)
    for _ in range(1536):
        length = rng.randrange(129)
        payload = [rng.randrange(256) for _ in range(length)]
        add((rng.randrange(MAX_MERGES + 1), length, *payload))

    invalid_inputs = [
        (), (-1, 0), (33, 0), (0, -1), (0, 513), (2, 1), (2, 0, 99),
        (2, 1, -1), (2, 1, 256), (0, 512, *([17] * 511)),
        (I64_MIN, 0), (I64_MAX, 0),
    ]
    for values in invalid_inputs:
        add(values)

    records = sorted(cases.items(), key=lambda item: (len(item[0]), item[0]))
    lines = [f"{len(records)}\n"]
    for (values, capacity), (result, payload) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(payload)} {capacity}{suffix} {payload.hex() or '-'}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("byte-output checker did not consume the full oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result, payload = oracle(values)
        capacity = case.get("workspace_bytes", len(payload))
        if capacity < len(payload):
            result, payload = -2, b""
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["output_capacity"] != capacity
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or record["measurement"]["result_checksum"] != fnv1a(payload)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/b/bpe_tokenizer")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "bpe-tokenizer-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
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
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(report_path)
    return 0 if all(item["status"] == "passed" for item in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
