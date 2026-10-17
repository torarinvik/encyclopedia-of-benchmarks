#!/usr/bin/env python3
"""Check Keys and Rooms ports against a Python graph traversal oracle."""

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

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "keys_and_rooms"
MAX_ROOMS = 1000
MAX_INPUT_LENGTH = 100001
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
WORKLOAD_PATH = ROOT / "benchmarks/k/keys_and_rooms/workload.json"


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 1 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    room_count = values[0]
    if room_count < 2 or room_count > MAX_ROOMS:
        return -1
    rooms: list[list[int]] = []
    cursor = 1
    for _ in range(room_count):
        if cursor >= len(values):
            return -1
        key_count = values[cursor]
        cursor += 1
        if key_count < 0 or key_count > room_count or cursor + key_count > len(values):
            return -1
        keys = values[cursor:cursor + key_count]
        if any(key < 0 or key >= room_count for key in keys):
            return -1
        rooms.append(keys)
        cursor += key_count
    if cursor != len(values):
        return -1

    visited = {0}
    stack = [0]
    while stack:
        room = stack.pop()
        for key in rooms[room]:
            if key not in visited:
                visited.add(key)
                stack.append(key)
    return int(len(visited) == room_count)


def pack_graph(rooms: list[list[int]]) -> list[int]:
    values = [len(rooms)]
    for keys in rooms:
        values.extend((len(keys), *keys))
    return values


def corpus(workload: dict) -> tuple[str, int]:
    cases = {tuple(encode_case(case, algorithm=ALGORITHM)): case["expected_result"] for case in workload["cases"]}
    for case in workload["cases"]:
        if oracle(case["input_values"]) != case["expected_result"]:
            raise ValueError(f"published workload disagrees with graph oracle: {case['id']}")

    for room_count in (2, 3):
        for edges in product((0, 1), repeat=room_count * room_count):
            rooms = [[target for target in range(room_count)
                      if edges[source * room_count + target]]
                     for source in range(room_count)]
            values = pack_graph(rooms)
            cases[tuple(values)] = oracle(values)

    malformed = [
        [], [1, 0, 0], [2, 0], [2, -1, 0], [2, I64_MIN, 0],
        [2, 3, 0, 1, 0, 0], [2, 2, 1], [2, 1, 2, 0], [2, 0, 0, 1],
        [2, I64_MAX, 0], [1001],
    ]
    cases.update({tuple(values): oracle(values) for values in malformed})

    rng = random.Random(20261015)
    for _ in range(512):
        room_count = rng.randint(2, 40)
        probability = rng.choice((0.01, 0.05, 0.2, 0.5))
        rooms = [[target for target in range(room_count) if rng.random() < probability]
                 for _ in range(room_count)]
        values = pack_graph(rooms)
        cases[tuple(values)] = oracle(values)

    empty_large_graph = pack_graph([[] for _ in range(MAX_ROOMS)])
    chain = pack_graph([[room + 1] for room in range(MAX_ROOMS - 1)] + [[]])
    dense_size = 316
    dense_graph = pack_graph([[target for target in range(dense_size) if target != room]
                              for room in range(dense_size)])
    cases[tuple(empty_large_graph)] = 0
    cases[tuple(chain)] = 1
    cases[tuple(dense_graph)] = 1
    max_length_with_trailing_data = [2, 0, 0] + [0] * (MAX_INPUT_LENGTH - 3)
    cases[tuple(max_length_with_trailing_data)] = -1

    lines = [str(len(cases)) + "\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(output)], cwd=ROOT, capture_output=True,
                               text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/keys_and_rooms")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "keys_and_rooms-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle graphs, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
