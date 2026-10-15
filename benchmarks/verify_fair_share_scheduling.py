#!/usr/bin/env python3
"""Compile and check fair-share scheduling ports against an exact integer oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file

ALGORITHM = "fair_share_scheduling"


def oracle(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 3 <= len(values) <= 323
            or any(type(value) is not int for value in values)):
        return -2, b""
    user_count, task_count, resources = values[:3]
    if not 0 <= user_count <= 64 or not 0 <= task_count <= 128 or not 0 <= resources <= 1_000_000:
        return -2, b""
    if len(values) != 3 + user_count + 2 * task_count:
        return -2, b""
    users: dict[int, int] = {}
    for offset in range(user_count):
        user_id = values[3 + offset]
        if not 0 <= user_id <= 63 or user_id in users:
            return -2, b""
        users[user_id] = 0
    task_start = 3 + user_count
    for task in range(task_count):
        owner, weight = values[task_start + 2 * task:task_start + 2 * task + 2]
        if not 0 <= owner <= 63 or not 0 <= weight <= 1_000_000:
            return -2, b""
        if owner in users:
            users[owner] += weight
    total_weight = sum(users.values())
    output = bytearray()
    for user_id, weight in sorted(users.items()):
        allocation = 0 if total_weight == 0 else weight * resources // total_weight
        for value in (user_id, weight, allocation):
            output.extend(value.to_bytes(8, "little", signed=True))
    return user_count, bytes(output)


def encode(values: list[int], result: int, output: bytes) -> str:
    values_text = "" if not values else " " + " ".join(map(str, values))
    encoded = output.hex() if output else "-"
    return f"{len(values)} {result} {len(output)}{values_text} {encoded}\n"


def corpus(workload: dict) -> tuple[str, int]:
    records: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        expected = oracle(values)
        if case["expected_result"] != expected[0] or case["expected_output_hex"] != expected[1].hex():
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        records[tuple(values)] = expected

    # Exhaust compact user/task sets, all user ID permutations, and resource totals.
    task_choices = tuple((owner, weight) for owner in range(3) for weight in range(3))
    for user_count in range(3):
        id_orders = itertools.permutations(range(3), user_count)
        for ids in id_orders:
            for task_count in range(3):
                for tasks in itertools.product(task_choices, repeat=task_count):
                    for resources in range(6):
                        values = [user_count, task_count, resources, *ids]
                        for task in tasks:
                            values.extend(task)
                        records[tuple(values)] = oracle(values)

    rng = random.Random(20261015)
    for _ in range(512):
        user_count = rng.randrange(0, 65)
        task_count = rng.randrange(0, 129)
        ids = rng.sample(range(64), user_count)
        values = [user_count, task_count, rng.randrange(0, 1_000_001), *ids]
        for _ in range(task_count):
            values.extend((rng.randrange(64), rng.randrange(0, 1_000_001)))
        records[tuple(values)] = oracle(values)

    malformed = (
        [], [1, 0, 10], [0, 0], [-1, 0, 10], [65, 0, 10], [0, 129, 10],
        [1, 0, -1, 0], [1, 0, 1_000_001, 0], [2, 0, 10, 7, 7],
        [1, 0, 10, 64], [1, 1, 10, 0, 64, 1], [1, 1, 10, 0, 0, -1],
        [1, 1, 10, 0, 0], [1, 0, 10, 0, 5],
    )
    for values in malformed:
        records[tuple(values)] = oracle(values)

    lines = [f"{len(records) + 1}\n"]
    lines.extend(encode(list(values), result, output)
                 for values, (result, output) in sorted(records.items()))
    # A valid user allocation must reject a zero-capacity output buffer.
    lines.append(encode([1, 1, 9, 4, 4, 2], -2, b""))
    return "".join(lines), len(records) + 1


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    link_shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
                  if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output",
                     extra_link_sources=link_shims)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    checked_count = json.loads(checked.stdout)["cases_checked"]
    if checked_count != case_count:
        raise RuntimeError(f"checker consumed {checked_count} of {case_count} cases")
    return {"language": language, "status": "passed", "oracle_cases": case_count,
            "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output/fair_share_scheduling")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/f/fair_share_scheduling/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / f"{ALGORITHM}-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} checker cases", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": len(results) == len(args.languages)
              and all(item["status"] == "passed" for item in results),
              "corpus_sha256": sha256_file(corpus_path),
              "verification_source_sha256": sha256_file(Path(__file__)),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
