#!/usr/bin/env python3
"""Verify root-to-leaf path-sum ports against an independent tree oracle."""

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
from functools import lru_cache

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "path_sum"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
MAX_NODES = 63


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    target, count_value = values[0], values[1]
    if not 0 <= count_value <= MAX_NODES or len(values) != 2 + 3 * count_value:
        return -1
    count = count_value
    if count == 0:
        return 0
    nodes = []
    for index in range(count):
        base = 2 + 3 * index
        value, left, right = values[base:base + 3]
        if not I32_MIN <= value <= I32_MAX:
            return -1
        if any(child != -1 and not 0 <= child < count for child in (left, right)):
            return -1
        nodes.append((value, left, right))

    stack = [(0, 0)]
    seen = set()
    found = False
    while stack:
        node, total = stack.pop()
        if node in seen:
            return -1
        seen.add(node)
        value, left, right = nodes[node]
        total += value
        if left == -1 and right == -1:
            found = found or total == target
        else:
            if left != -1:
                stack.append((left, total))
            if right != -1:
                stack.append((right, total))
    if len(seen) != count:
        return -1
    return 1 if found else 0


def pack(target: int, nodes: list[list[int]]) -> tuple[int, ...]:
    return (target, len(nodes), *(value for row in nodes for value in row))


@lru_cache(maxsize=None)
def shapes(size: int) -> tuple[tuple | None, ...]:
    if size == 0:
        return (None,)
    result = []
    for left_size in range(size):
        right_size = size - 1 - left_size
        for left in shapes(left_size):
            for right in shapes(right_size):
                result.append((left, right))
    return tuple(result)


def numbered_nodes(shape: tuple | None, values: tuple[int, ...]) -> list[list[int]]:
    nodes: list[list[int]] = []
    def visit(current: tuple | None) -> int:
        if current is None:
            return -1
        index = len(nodes)
        nodes.append([values[index], -1, -1])
        left = visit(current[0])
        right = visit(current[1])
        nodes[index][1] = left
        nodes[index][2] = right
        return index
    visit(shape)
    return nodes


def path_sums(nodes: list[list[int]]) -> list[int]:
    if not nodes:
        return []
    sums = []
    stack = [(0, 0)]
    while stack:
        node, total = stack.pop()
        total += nodes[node][0]
        left, right = nodes[node][1:]
        if left == -1 and right == -1:
            sums.append(total)
        else:
            if left != -1:
                stack.append((left, total))
            if right != -1:
                stack.append((right, total))
    return sums


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for size in range(5):
        for shape in shapes(size):
            for node_values in product((-1, 0, 1), repeat=size):
                nodes = numbered_nodes(shape, node_values)
                for target in range(-5, 6):
                    packed = pack(target, nodes)
                    cases[packed] = oracle(list(packed))

    rng = random.Random(20261015)
    value_pool = [I32_MIN, I32_MIN + 1, -100, -1, 0, 1, 100, I32_MAX - 1, I32_MAX]
    for _ in range(512):
        count = rng.randrange(0, MAX_NODES + 1)
        nodes = []
        if count:
            nodes = [[rng.choice(value_pool), -1, -1]]
            slots = [(0, 1), (0, 2)]
            for index in range(1, count):
                slot_index = rng.randrange(len(slots))
                parent, side = slots.pop(slot_index)
                nodes[parent][side] = index
                nodes.append([rng.choice(value_pool), -1, -1])
                slots.extend(((index, 1), (index, 2)))
        sums = path_sums(nodes)
        target = rng.choice(sums) if sums and rng.randrange(2) else rng.choice(
            [I64_MIN, -10, -1, 0, 1, 10, I64_MAX])
        packed = pack(target, nodes)
        cases[packed] = oracle(list(packed))

    malformed = (
        (), (0,), (0, -1), (0, 64), (0, 1, 7),
        (0, 1, I32_MAX + 1, -1, -1),
        (0, 1, 7, 1, -1),
        (0, 1, 7, -2, -1),
        (0, 2, 1, 1, 1, 2, -1, -1),
        (0, 2, 1, -1, -1, 2, -1, -1),
        (0, 2, 1, 1, -1, 2, 0, -1),
    )
    for packed in malformed:
        cases[packed] = oracle(list(packed))
    for case in workload["cases"]:
        values = tuple(encode_case(case, algorithm=ALGORITHM))
        expected = oracle(list(values))
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with tree oracle: {case['id']}")
        cases[values] = expected

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
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/path_sum")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/p/path_sum/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle trees, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "results": sorted(results, key=lambda item: item["language"]),
              "all_passed": not failures and len(results) == len(args.languages)}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
