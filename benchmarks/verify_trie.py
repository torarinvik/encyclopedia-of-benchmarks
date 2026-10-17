#!/usr/bin/env python3
"""Check trie operation traces against an independent set-of-words oracle."""
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
from run_i64_array_scalar import encode_case

ALGORITHM = "trie"
INVALID = -1
MAX_VALUES = 1024
MAX_WORD_LENGTH = 128
HASH_MOD = 1_000_000_007
OFFSET = 1_000_000


def word_hash(word: str) -> int:
    value = len(word) + 1
    for character in word:
        value = (value * 31 + ord(character) - 96) % HASH_MOD
    return value


def encode_record(opcode: int, word: str = "") -> tuple[int, ...]:
    return (opcode, len(word), *(ord(character) for character in word))


def oracle(values: list[int]) -> int:
    if len(values) > MAX_VALUES:
        return INVALID
    words: set[str] = set()
    checksum = 0
    position = 0
    operation = 0
    while position < len(values):
        if position + 1 >= len(values):
            return INVALID
        opcode, word_length = values[position:position + 2]
        if opcode < 0 or opcode > 5 or word_length < 0 or word_length > MAX_WORD_LENGTH:
            return INVALID
        if opcode == 5 and word_length != 0:
            return INVALID
        if position + 2 + word_length > len(values):
            return INVALID
        characters = values[position + 2:position + 2 + word_length]
        if any(character < 97 or character > 122 for character in characters):
            return INVALID
        word = "".join(chr(character) for character in characters)
        observed = 0
        if opcode == 0:
            observed = int(word not in words)
            words.add(word)
        elif opcode == 1:
            observed = int(word in words)
            words.discard(word)
        elif opcode == 2:
            observed = int(word in words)
        elif opcode == 3:
            observed = int(any(active.startswith(word) for active in words))
        elif opcode == 4:
            observed = sum(active.startswith(word) for active in words)
        else:
            observed = len(words)
        checksum += (operation + 1) * (observed + OFFSET)
        position += 2 + word_length
        operation += 1
    checksum += (operation + 1) * (sum(word_hash(word) for word in words) + OFFSET)
    return checksum


def checker_corpus(cases: dict[tuple[int, ...], int]) -> str:
    lines = [f"{len(cases)}\n"]
    for values in sorted(cases):
        expected = oracle(list(values))
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines)


def verify(language: str, directory: Path, elisa_compiler: str | None, data: str,
           case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"array scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume complete oracle corpus")
    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in records_path.read_text().splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM)
        expected = oracle(values)
        if (expected != case["expected_result"] or record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != expected
                or record["measurement"]["observed_result"] != expected
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(records_path), "recorder_output_sha256": sha256_file(records_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_scalar/t/trie")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/t/trie/workload.json").read_text())
    cases: dict[tuple[int, ...], int] = {}

    tokens = [encode_record(0, ""), encode_record(0, "a"), encode_record(0, "ab"),
              encode_record(1, "a"), encode_record(1, "ab"), encode_record(2, "a"),
              encode_record(2, "b"), encode_record(3, ""), encode_record(3, "a"),
              encode_record(4, ""), encode_record(4, "a"), encode_record(5)]
    for size in range(4):
        for sequence in itertools.product(tokens, repeat=size):
            packed = tuple(value for record in sequence for value in record)
            cases[packed] = oracle(list(packed))

    rng = random.Random(20261014)
    alphabet = "abcd"
    for _ in range(1024):
        packed: list[int] = []
        target_operations = rng.randrange(1, 100)
        for _step in range(target_operations):
            opcode = rng.randrange(6)
            word = "" if opcode == 5 else "".join(rng.choice(alphabet) for _ in range(rng.randrange(0, 13)))
            record = encode_record(opcode, word)
            if len(packed) + len(record) > MAX_VALUES:
                break
            packed.extend(record)
        key = tuple(packed)
        cases[key] = oracle(list(key))

    for _ in range(512):
        size = rng.randrange(0, 81)
        packed = tuple(rng.choice((-1, 0, 1, 2, 3, 4, 5, 6, 97, 98, 122, 123, 129, 1000000))
                       for _ in range(size))
        cases[packed] = oracle(list(packed))

    maximum_word = "z" * MAX_WORD_LENGTH
    long_case = (encode_record(0, maximum_word) + encode_record(3, "z" * 64)
                 + encode_record(4, "z") + encode_record(2, maximum_word))
    cases[long_case] = oracle(list(long_case))
    max_empty_trace = tuple(value for _ in range(512) for value in encode_record(0, ""))
    cases[max_empty_trace] = oracle(list(max_empty_trace))
    over_limit = tuple([0] * (MAX_VALUES + 1))
    cases[over_limit] = INVALID

    for case in workload["cases"]:
        packed = tuple(encode_case(case, algorithm=ALGORITHM))
        expected = oracle(list(packed))
        if expected != case["expected_result"]:
            parser.error(f"workload oracle mismatch: {case['id']}")
        cases[packed] = expected

    data = checker_corpus(cases)
    results: list[dict] = []
    failures: list[dict] = []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {pool.submit(verify, language, directory / language, args.elisa_compiler,
                            data, len(cases), workload): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as exc:
                failures.append({"language": language, "error": str(exc)})
                print(f"FAIL {language}: {exc}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {language}: {len(cases)} oracle traces, {result['workload_records']} workload records",
                  flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "oracle_cases": len(cases), "results": sorted(results, key=lambda row: row["language"]),
              "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {report_path}")
    return 0 if not failures and len(results) == len(args.languages) else 1


if __name__ == "__main__":
    raise SystemExit(main())
