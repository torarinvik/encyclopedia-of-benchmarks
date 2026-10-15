#!/usr/bin/env python3
"""Check Gale-Shapley ports against an independent stable-matching oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import itertools
import json
from pathlib import Path
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build

ALGORITHM = "gale_shapley"
FAMILY = "i64_array_bytes_output"


def pack(proposer_preferences: list[list[int]], accepter_preferences: list[list[int]]) -> list[int]:
    count = len(proposer_preferences)
    return [count, *(value for row in proposer_preferences for value in row),
            *(value for row in accepter_preferences for value in row)]


def proposer_optimal_matching(values: list[int]) -> bytes | None:
    if (not 1 <= len(values) <= 66 or any(type(value) is not int for value in values)
            or not 0 <= values[0] <= 5):
        return None
    count = values[0]
    if len(values) != 1 + 2 * count * count:
        return None
    proposers = [values[1 + p * count:1 + (p + 1) * count] for p in range(count)]
    offset = 1 + count * count
    accepters = [values[offset + a * count:offset + (a + 1) * count]
                 for a in range(count)]
    expected_ids = set(range(count))
    if any(set(row) != expected_ids for row in proposers + accepters):
        return None
    if count == 0:
        return b""

    proposer_ranks = [{accepter: rank for rank, accepter in enumerate(row)} for row in proposers]
    accepter_ranks = [{proposer: rank for rank, proposer in enumerate(row)} for row in accepters]
    stable_matchings: list[tuple[int, ...]] = []
    for matching in itertools.permutations(range(count)):
        inverse = [0] * count
        for proposer, accepter in enumerate(matching):
            inverse[accepter] = proposer
        stable = True
        for proposer in range(count):
            for accepter in range(count):
                if (proposer_ranks[proposer][accepter] < proposer_ranks[proposer][matching[proposer]]
                        and accepter_ranks[accepter][proposer] < accepter_ranks[accepter][inverse[accepter]]):
                    stable = False
                    break
            if not stable:
                break
        if stable:
            stable_matchings.append(matching)
    if not stable_matchings:
        raise AssertionError("complete strict preference lists must have a stable matching")
    best = min(stable_matchings,
               key=lambda matching: tuple(proposer_ranks[p][matching[p]] for p in range(count)))
    best_ranks = tuple(proposer_ranks[p][best[p]] for p in range(count))
    if any(any(proposer_ranks[p][matching[p]] < best_ranks[p] for p in range(count))
           for matching in stable_matchings):
        raise AssertionError("brute-force oracle failed to select a proposer-optimal matching")
    return bytes(best)


def corpus(workload: dict) -> tuple[str, int, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        matching = proposer_optimal_matching(values)
        expected = (-2, b"") if matching is None else (len(matching), matching)
        if case["expected_result"] != expected[0] or case["expected_order"] != list(expected[1]):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(values)] = expected

    two_person_preferences = list(itertools.permutations(range(2)))
    for profile in itertools.product(two_person_preferences, repeat=4):
        values = pack([list(row) for row in profile[:2]], [list(row) for row in profile[2:]])
        matching = proposer_optimal_matching(values)
        assert matching is not None
        cases[tuple(values)] = (len(matching), matching)

    rng = random.Random(20261014)
    for count in range(3, 6):
        for _ in range(48):
            proposers = [rng.sample(range(count), count) for _ in range(count)]
            accepters = [rng.sample(range(count), count) for _ in range(count)]
            values = pack(proposers, accepters)
            matching = proposer_optimal_matching(values)
            assert matching is not None
            cases[tuple(values)] = (len(matching), matching)

    lines = [str(len(cases) + 5)]
    for values, (result, output) in sorted(cases.items()):
        lines.extend((f"{len(values)} {result} {len(output)}",
                      " ".join(map(str, values)), output.hex() if output else "-"))
    for count in range(1, 6):
        values = pack([list(range(count)) for _ in range(count)],
                      [list(range(count)) for _ in range(count)])
        lines.extend((f"{len(values)} -2 0", " ".join(map(str, values)), "-"))
    return "\n".join(lines) + "\n", len(cases), len(cases) + 5


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family=FAMILY)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"stable-matching C ABI check failed: {checked.stderr}")
    actual = json.loads(checked.stdout)["cases_checked"]
    if actual != case_count:
        raise RuntimeError(f"checker processed {actual} cases, expected {case_count}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count - 5, "capacity_checks": 5,
            "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/g/gale_shapley/workload.json")
                          .read_text(encoding="utf-8"))
    data, _, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / ALGORITHM / language,
                                args.elisa_compiler, data, case_count): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                results.append(job.result())
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
    for result in sorted(results, key=lambda item: item["language"]):
        print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
