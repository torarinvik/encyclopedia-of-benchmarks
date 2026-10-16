#!/usr/bin/env python3
"""Verify all full-binary-tree predicate ports against generated rooted trees."""

from __future__ import annotations
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import lru_cache
from itertools import product
import argparse
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "binary_tree_is_full"
WORKLOAD = ROOT / "benchmarks/b/binary_tree_is_full/workload.json"
MAX_NODES = 1024


def oracle(values: tuple[int, ...]) -> int:
    if not values or not 1 <= values[0] <= MAX_NODES or len(values) != 2 + 2 * values[0]:
        return -1
    count, root = values[:2]
    if not 0 <= root < count:
        return -1
    children = []
    parents = [0] * count
    full = True
    for node in range(count):
        left, right = values[2 + 2 * node:4 + 2 * node]
        if (left < -1 or left >= count or right < -1 or right >= count
                or left == node or right == node):
            return -1
        for child in (left, right):
            if child >= 0:
                parents[child] += 1
                if parents[child] > 1:
                    return -1
        if (left < 0) != (right < 0):
            full = False
        children.append((left, right))
    if parents[root] != 0 or any(parents[node] != 1 for node in range(count) if node != root):
        return -1
    seen = set()
    pending = [root]
    while pending:
        node = pending.pop()
        if node in seen:
            return -1
        seen.add(node)
        pending.extend(child for child in children[node] if child >= 0)
    return int(full) if len(seen) == count else -1


@lru_cache(maxsize=None)
def shapes(count: int) -> tuple[object, ...]:
    if count == 0:
        return (None,)
    return tuple((left, right)
                 for left_count in range(count)
                 for left, right in product(shapes(left_count), shapes(count - 1 - left_count)))


def encode_shape(shape: object) -> tuple[int, ...]:
    children: list[list[int]] = []
    def append(item: object) -> int:
        if item is None:
            return -1
        node = len(children)
        children.append([-1, -1])
        left_shape, right_shape = item
        children[node][0] = append(left_shape)
        children[node][1] = append(right_shape)
        return node
    root = append(shape)
    return (len(children), root, *(child for row in children for child in row))


def random_tree(rng: random.Random, count: int, chain: bool = False) -> tuple[int, ...]:
    children = [[-1, -1] for _ in range(count)]
    free = [(0, 0), (0, 1)]
    for node in range(1, count):
        if chain:
            parent, side = node - 1, 1
            free.remove((parent, side))
        else:
            parent, side = free.pop(rng.randrange(len(free)))
        children[parent][side] = node
        free.extend(((node, 0), (node, 1)))
    permutation = list(range(count))
    rng.shuffle(permutation)
    remap = {old: new for new, old in enumerate(permutation)}
    reordered = [[-1 if child < 0 else remap[child] for child in children[old]]
                 for old in permutation]
    return (count, remap[0], *(child for row in reordered for child in row))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    def add(values: tuple[int, ...], expected: int | None = None) -> None:
        actual = oracle(values)
        if expected is not None and actual != expected:
            raise ValueError("published full-tree workload disagrees with oracle")
        cases[values] = actual
    for case in workload["cases"]:
        add(tuple(case["input_values"]), case["expected_result"])
    for count in range(1, 8):
        for shape in shapes(count):
            add(encode_shape(shape))
    rng = random.Random(20261015)
    for count in (1, 2, 3, 7, 31, 127, 512, MAX_NODES):
        for _ in range(16 if count < MAX_NODES else 4):
            add(random_tree(rng, count))
    add(random_tree(rng, MAX_NODES, chain=True))
    invalid = [(), (0,), (1, 0), (1, 0, -1), (2, 0, 1, -1, -1, -1),
               (2, 0, 1, 1, -1, -1), (2, 1, -1, 0, -1, -1),
               (2, 0, 2, -1, -1, -1), (1, 0, 0, -1),
               (MAX_NODES + 1, 0)]
    for values in invalid:
        add(values)
    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        lines.append(f"{len(values)} {expected}" + (" " + " ".join(map(str, values)) if values else "") + "\n")
    return "".join(lines), len(records)


def verify(language: str, elisa_compiler: str | None, directory: Path,
           check_input: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=check_input, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"full-tree oracle check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete generated-tree corpus")
    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    completed = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=180)
    if completed.returncode:
        raise RuntimeError(f"full-tree workload recorder failed: {completed.stdout}\n{completed.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != case["input_values"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"workload result/provenance mismatch: {case['id']}")
    return {"language": language, "status": "passed", "oracle_cases": case_count,
            "workload_records": len(records), "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "verification_records": str(records_path),
            "verification_records_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/binary_tree_is_full")
    parser.add_argument("--jobs", type=int, default=3)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages) or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    workload = json.loads(WORKLOAD.read_text(encoding="utf-8"))
    check_input, case_count = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(verify, lang, args.elisa_compiler, args.build_dir / lang,
                               check_input, case_count, workload): lang for lang in args.languages}
        for future in as_completed(futures):
            lang = futures[future]
            try:
                results.append(future.result())
            except Exception as error:
                failures.append((lang, str(error)))
                print(f"FAIL {ALGORITHM}/{lang}: {error}", file=sys.stderr, flush=True)
    results.sort(key=lambda result: result["language"])
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures and len(results) == len(args.languages),
              "oracle_cases_per_language": case_count, "results": results, "failures": failures}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "passed" if report["all_passed"] else "failed",
                      "oracle_cases_per_language": case_count,
                      "languages": [result["language"] for result in results],
                      "report": str(report_path)}, indent=2))
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
