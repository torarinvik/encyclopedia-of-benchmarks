#!/usr/bin/env python3
"""Verify autocomplete trie ports against an independent byte-level oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import combinations
import json
from pathlib import Path
import platform
import random
import struct
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "autocomplete_using_trie"
WORKLOAD_PATH = ROOT / "benchmarks/a/autocomplete_using_trie/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def oracle(values: tuple[int, ...] | list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) < 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    word_count = values[0]
    if not 0 <= word_count <= 32:
        return -1, b""
    position = 1
    words: set[bytes] = set()
    for _ in range(word_count):
        if position >= len(values):
            return -1, b""
        length = values[position]
        position += 1
        if not 1 <= length <= 16 or position + length > len(values):
            return -1, b""
        word_values = values[position:position + length]
        if any(not 97 <= value <= 122 for value in word_values):
            return -1, b""
        words.add(bytes(word_values))
        position += length
    if position >= len(values):
        return -1, b""
    query_count = values[position]
    position += 1
    if not 0 <= query_count <= 16:
        return -1, b""
    prefixes = []
    for _ in range(query_count):
        if position >= len(values):
            return -1, b""
        length = values[position]
        position += 1
        if not 0 <= length <= 16 or position + length > len(values):
            return -1, b""
        prefix_values = values[position:position + length]
        if any(not 97 <= value <= 122 for value in prefix_values):
            return -1, b""
        prefixes.append(bytes(prefix_values))
        position += length
    if position != len(values):
        return -1, b""

    output_values = [query_count]
    for prefix in prefixes:
        completions = sorted(word for word in words if word.startswith(prefix))
        output_values.append(len(completions))
        for word in completions:
            output_values.extend((len(word), *word))
    output = b"".join(struct.pack("<q", value) for value in output_values)
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output


def encode_input(words: list[bytes], prefixes: list[bytes]) -> tuple[int, ...]:
    values = [len(words)]
    for word in words:
        values.extend((len(word), *word))
    values.append(len(prefixes))
    for prefix in prefixes:
        values.extend((len(prefix), *prefix))
    return tuple(values)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...] | list[int], capacity: int | None = None) -> None:
        packed = tuple(values)
        result, output = oracle(packed, capacity)
        runner_result, runner_output = expected_output(list(packed), ALGORITHM)
        if (runner_result, runner_output) != oracle(packed):
            raise ValueError(f"independent and recorder oracles disagree for {packed[:12]}")
        cases[(packed, result, output)] = (result, output)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = oracle(values, case.get("workspace_bytes"))
        if (case.get("expected_result") != result
                or case.get("expected_output_hex", "") != output.hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values, case.get("workspace_bytes"))

    small_words = [b"a", b"aa", b"ab", b"b", b"ba", b"bb"]
    prefixes = (b"", b"a", b"b", b"aa", b"c")
    for size in range(len(small_words) + 1):
        for selected in combinations(small_words, size):
            words = list(selected)
            add(encode_input(words, list(prefixes)))
            if words:
                add(encode_input(words + [words[0], words[0]], list(prefixes)))

    rng = random.Random(20261015)
    for _ in range(256):
        words = [bytes(rng.randrange(97, 101) for _ in range(rng.randrange(1, 9)))
                 for _ in range(rng.randrange(33))]
        prefixes = [bytes(rng.randrange(97, 101) for _ in range(rng.randrange(17)))
                    for _ in range(rng.randrange(17))]
        add(encode_input(words, prefixes))

    invalid_inputs = [
        (), (-1, 0), (33, 0), (1,), (1, 0, 0), (1, 17, *([97] * 17), 0),
        (1, 1, 65, 0), (0,), (0, 17), (0, 1, -1), (0, 1, 17, *([97] * 17),),
        (0, 1, 1, 65), (0, 1, 0, 97), (0, 1, 1),
    ]
    for values in invalid_inputs:
        add(values)

    # Force the function to reject a valid request when the caller supplies no
    # output space; the checker also verifies that the zero-capacity buffer stays untouched.
    add(encode_input([], [b""]), capacity=0)

    lines = [f"{len(cases)}\n"]
    for (values, result, output), _ in sorted(cases.items()):
        encoded = output.hex() if output else "-"
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)}{suffix} {encoded}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        result, _ = oracle(case["input_values"], case.get("workspace_bytes"))
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
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
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/autocomplete_using_trie")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")

    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
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

    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
