#!/usr/bin/env python3
"""Check word-break ports against an independent memoized recursive oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from functools import lru_cache
import hashlib
import json
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "word_break"
MAX_TEXT = 64
MAX_WORDS = 32
MAX_WORD_LENGTH = 32
MAX_PACKED_LENGTH = 2 + MAX_TEXT + MAX_WORDS * (1 + MAX_WORD_LENGTH)
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def pack(text: str, words: list[str]) -> list[int]:
    values = [len(text), len(words), *(ord(character) - 96 for character in text)]
    for word in words:
        codes = [ord(character) - 96 for character in word]
        values.extend((len(codes), *codes, *([0] * (MAX_WORD_LENGTH - len(codes)))))
    return values


def oracle(values: list[int]) -> int:
    """Validate the packed contract, then solve recursively with memoization."""
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_PACKED_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    text_length, word_count = values[:2]
    if not 0 <= text_length <= MAX_TEXT or not 0 <= word_count <= MAX_WORDS:
        return -1
    dictionary_start = 2 + text_length
    if len(values) != dictionary_start + word_count * (1 + MAX_WORD_LENGTH):
        return -1
    text = tuple(values[2:dictionary_start])
    if any(not 1 <= code <= 26 for code in text):
        return -1
    words: list[tuple[int, ...]] = []
    for word_index in range(word_count):
        slot = dictionary_start + word_index * (1 + MAX_WORD_LENGTH)
        word_length = values[slot]
        if not 1 <= word_length <= MAX_WORD_LENGTH:
            return -1
        codes = values[slot + 1:slot + 1 + word_length]
        padding = values[slot + 1 + word_length:slot + 1 + MAX_WORD_LENGTH]
        if any(not 1 <= code <= 26 for code in codes) or any(code != 0 for code in padding):
            return -1
        words.append(tuple(codes))

    @lru_cache(maxsize=None)
    def can_segment(position: int) -> bool:
        if position == len(text):
            return True
        for word in words:
            end = position + len(word)
            if end <= len(text) and text[position:end] == word and can_segment(end):
                return True
        return False

    return int(can_segment(0))


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"published workload disagrees with recursive oracle: {case['id']}")
        cases[tuple(values)] = expected

    # Exhaust every binary-alphabet text through length six and every dictionary
    # subset of {a, b, aa, ab, ba, bb}.
    alphabet = ("a", "b")
    word_universe = ("a", "b", "aa", "ab", "ba", "bb")
    for text_length in range(7):
        for number in range(1 << text_length):
            text = "".join(alphabet[(number >> bit) & 1] for bit in range(text_length))
            for dictionary_mask in range(1 << len(word_universe)):
                words = [word for bit, word in enumerate(word_universe)
                         if dictionary_mask & (1 << bit)]
                values = pack(text, words)
                cases[tuple(values)] = oracle(values)

    rng = random.Random(20261015)
    for _ in range(512):
        text = "".join(rng.choice("abcd") for _ in range(rng.randrange(0, MAX_TEXT + 1)))
        words = ["".join(rng.choice("abcd") for _ in range(rng.randrange(1, 13)))
                 for _ in range(rng.randrange(0, MAX_WORDS + 1))]
        values = pack(text, words)
        cases[tuple(values)] = oracle(values)

    invalid = [
        [], [0], [-1, 0], [MAX_TEXT + 1, 0], [0, -1], [0, MAX_WORDS + 1],
        [1, 0], [1, 0, 0], [0, 0, 1],
        [0, 1, 0, *([0] * 32)],
        [0, 1, MAX_WORD_LENGTH + 1, *([0] * 32)],
        [0, 1, 1, 27, *([0] * 31)],
        [0, 1, 1, 1, 1, *([0] * 30)],
        [0, 0, 1],
        [0, 0, *([0] * (MAX_PACKED_LENGTH + 1 - 2))],
        [I64_MIN, 0], [0, I64_MAX],
    ]
    for values in invalid:
        cases[tuple(values)] = oracle(values)

    lines = [f"{len(cases)}\n"]
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

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"),
                               "--samples", "1", "--warmups", "0", "--repetitions", "1",
                               "--output", str(records_path)],
                              cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
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
            "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
            "workload_records": len(records),
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path),
            "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/word_break")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/w/word_break/workload.json")
                          .read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "word-break-corpus.txt").write_text(data, encoding="utf-8")

    results = []
    failures = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language
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
    if failures:
        return 1
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": True,
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
