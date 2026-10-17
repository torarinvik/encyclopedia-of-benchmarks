#!/usr/bin/env python3
"""Verify alien-dictionary ports against an independent packed-input oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
from itertools import permutations, product
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM = "verifying_an_alien_dictionary"
MIN_WORDS, MAX_WORDS = 1, 100
MIN_WORD_LENGTH, MAX_WORD_LENGTH = 1, 20
MAX_INPUT_LENGTH = 1 + 26 + MAX_WORDS * (1 + MAX_WORD_LENGTH)
WORKLOAD_PATH = ROOT / "benchmarks/v/verifying_an_alien_dictionary/workload.json"


def encode_words(words: list[str], order: str) -> list[int]:
    values = [len(words), *(ord(letter) for letter in order)]
    for word in words:
        values.extend((len(word), *(ord(letter) for letter in word)))
    return values


def oracle(values: list[int]) -> int:
    if (not isinstance(values, list) or not 27 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    word_count = values[0]
    if not MIN_WORDS <= word_count <= MAX_WORDS:
        return -1

    alphabet = values[1:27]
    if (len(alphabet) != 26 or any(not ord("a") <= value <= ord("z") for value in alphabet)
            or len(set(alphabet)) != 26):
        return -1
    ranks = {letter: rank for rank, letter in enumerate(alphabet)}

    words: list[bytes] = []
    position = 27
    for _ in range(word_count):
        if position >= len(values):
            return -1
        length = values[position]
        position += 1
        if not MIN_WORD_LENGTH <= length <= MAX_WORD_LENGTH or position + length > len(values):
            return -1
        word = values[position:position + length]
        if any(not ord("a") <= letter <= ord("z") for letter in word):
            return -1
        words.append(bytes(word))
        position += length
    if position != len(values):
        return -1

    for left, right in zip(words, words[1:]):
        for left_letter, right_letter in zip(left, right):
            if left_letter != right_letter:
                if ranks[left_letter] > ranks[right_letter]:
                    return 0
                break
        else:
            if len(left) > len(right):
                return 0
    return 1


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}

    def add(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))

    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if expected != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[tuple(values)] = expected

    small_words = ["".join(chars) for length in range(1, 4)
                   for chars in product("abc", repeat=length)]
    for prefix in permutations("abc"):
        order = "".join(prefix) + "".join(letter for letter in "abcdefghijklmnopqrstuvwxyz"
                                          if letter not in prefix)
        for left in small_words:
            for right in small_words:
                add(encode_words([left, right], order))

    add(encode_words(["a" * MAX_WORD_LENGTH, "a" * MAX_WORD_LENGTH],
                     "abcdefghijklmnopqrstuvwxyz"))
    add(encode_words(["z" * MAX_WORD_LENGTH] * MAX_WORDS,
                     "zyxwvutsrqponmlkjihgfedcba"))

    alphabet = list("abcdefghijklmnopqrstuvwxyz")
    for invalid in (
        [], [0, *map(ord, alphabet)], [MAX_WORDS + 1, *map(ord, alphabet)],
        [1, *map(ord, alphabet[:-1])], [1, *map(ord, "aacdefghijklmnopqrstuvwxyz"), 1, 97],
        [1, *map(ord, alphabet)],
        [1, *map(ord, alphabet), 0],
        [1, *map(ord, alphabet), MAX_WORD_LENGTH + 1, *([97] * (MAX_WORD_LENGTH + 1))],
        [1, *map(ord, alphabet), 2, 97],
        [1, *map(ord, alphabet), 1, 65],
        [1, *map(ord, alphabet), 1, 123],
        [1, *map(ord, alphabet), 1, 97, 99],
        [1, *map(ord, alphabet), 1, 97, -(2**63)],
    ):
        add(invalid)

    rng = random.Random(20261015)
    for _ in range(768):
        letters = list("abcdefghijklmnopqrstuvwxyz")
        rng.shuffle(letters)
        words = ["".join(rng.choice(letters[:8]) for _ in range(rng.randint(1, MAX_WORD_LENGTH)))
                 for _ in range(rng.randint(MIN_WORDS, MAX_WORDS))]
        packed = encode_words(words, "".join(letters))
        add(packed)
        mutation = rng.randrange(4)
        if mutation == 0:
            packed[1] = packed[2]
        elif mutation == 1:
            packed[-1] = ord("A")
        elif mutation == 2:
            packed.pop()
        else:
            packed.append(0)
        add(packed)

    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"i64-array C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
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
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/verifying_an_alien_dictionary")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / f"{ALGORITHM}-corpus.txt").write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count, workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
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
