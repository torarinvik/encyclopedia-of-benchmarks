#!/usr/bin/env python3
"""Verify affine-cipher ports against an independent modular-arithmetic oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import expected_output

ALGORITHM = "affine_cipher"
FAMILY = "i64_array_bytes_output"


def pack(mode: int, key_a: int, key_b: int, alphabet: bytes, text: bytes) -> tuple[int, ...]:
    return (mode, key_a, key_b, len(alphabet), *alphabet, len(text), *text)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...]) -> None:
        cases[values] = expected_output(list(values), ALGORITHM)

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = expected_output(list(values), ALGORITHM)
        if (case["expected_result"] != result
                or case["expected_output_hex"] != output.hex()):
            raise ValueError(f"published workload oracle mismatch: {case['id']}")
        add(values)

    # Enumerate every key, mode, and symbol for small moduli and the A-Z source alphabet.
    for alphabet_length in (*range(2, 10), 26):
        alphabet = bytes(range(32, 32 + alphabet_length))
        for key_a in range(1, alphabet_length + 1):
            if math.gcd(key_a, alphabet_length) != 1:
                continue
            for key_b in range(alphabet_length):
                for mode in (0, 1):
                    add(pack(mode, key_a, key_b, alphabet, alphabet))

    printable = bytes(range(32, 127))
    for mode, key_a, key_b in ((0, 7, 11), (1, 7, 11), (0, 47, 80), (1, 47, 80)):
        add(pack(mode, key_a, key_b, printable, printable))

    rng = random.Random(20261015)
    for _ in range(768):
        alphabet_length = rng.randrange(2, 96)
        alphabet = bytes(rng.sample(range(32, 127), alphabet_length))
        key_candidates = [value for value in range(1, alphabet_length + 1)
                          if math.gcd(value, alphabet_length) == 1]
        key_a = rng.choice(key_candidates)
        key_b = rng.randrange(alphabet_length)
        text = bytes(rng.choice(alphabet) for _ in range(rng.randrange(513)))
        add(pack(rng.randrange(2), key_a, key_b, alphabet, text))

    # Invalid mode, non-invertible keys, malformed alphabets/text, and size boundaries.
    add(pack(2, 5, 1, b"ABCDE", b"ABC"))
    add(pack(0, 2, 1, b"0123456789", b"123"))
    add(pack(0, 5, -1, b"0123456789", b"123"))
    add(pack(0, 5, 10, b"0123456789", b"123"))
    add(pack(0, 1_000_001, 0, b"ABCDE", b"ABC"))
    add(pack(0, 1, 0, b"AABC", b"AB"))
    add(pack(0, 1, 0, b"ABC", b"AD"))
    add(pack(0, 1, 0, b"A\nB", b"AB"))
    add(pack(0, 1, 0, b"ABC", b"A\n"))
    add(pack(0, 1, 0, b"A", b"A"))
    too_long = pack(0, 7, 1, bytes(range(32, 127)), b"A" * 513)
    add(too_long)
    truncated = list(pack(0, 1, 0, b"ABC", b"AB"))
    truncated[7] = 3
    add(tuple(truncated))

    lines = [f"{len(cases)}\n"]
    for values, (result, output) in sorted(cases.items()):
        values_text = " ".join(map(str, values))
        output_text = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)} {values_text} {output_text}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family=FAMILY)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    rows = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(rows) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, row in zip(workload["cases"], rows):
        expected, _output = expected_output(case["input_values"], ALGORITHM)
        if (row["algorithm"] != ALGORITHM
                or row["implementation"]["language"] != language
                or row["implementation"]["source_sha256"] != manifest["source_sha256"]
                or row["workload"]["input_values"] != case["input_values"]
                or row["workload"]["expected_result"] != expected
                or row["measurement"]["observed_result"] != expected
                or len(row["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(rows), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/affine_cipher")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/a/affine_cipher/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    (directory / "affine-cipher-corpus.txt").write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, language, directory / language,
                                   args.elisa_compiler, data, case_count, workload): language
                   for language in args.languages}
        for future in as_completed(futures):
            language = futures[future]
            try:
                result = future.result()
            except Exception as error:
                failures.append((language, str(error)))
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                continue
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                  f"{result['workload_records']} workload records", flush=True)

    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]), "failures": failures}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
