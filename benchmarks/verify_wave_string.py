#!/usr/bin/env python3
"""Verify wave_string ports against an independent ASCII transformation oracle."""

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
from run_i64_array_bytes_output import expected_output, fnv1a

ALGORITHM = "wave_string"
WORKLOAD_PATH = ROOT / "benchmarks/w/wave_string/workload.json"
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_TEXT_LENGTH = 512


def oracle(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not values
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or len(values) != 1 + text_length:
        return -1, b""
    text = values[1:]
    if any(not 32 <= byte <= 126 for byte in text):
        return -1, b""

    output = bytearray()
    variant_count = 0
    for position, byte in enumerate(text):
        if not (65 <= byte <= 90 or 97 <= byte <= 122):
            continue
        output.extend((text_length & 255, text_length >> 8))
        for index in range(text_length):
            current = text[index]
            if index == position and 97 <= current <= 122:
                current -= 32
            output.append(current)
        variant_count += 1
    return variant_count, bytes(output)


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...] | list[int]) -> None:
        packed = tuple(values)
        result = oracle(packed)
        if expected_output(list(packed), ALGORITHM) != result:
            raise ValueError(f"independent and recorder oracles disagree for {packed[:12]}")
        cases[packed] = result

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = oracle(values)
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != result
                or case.get("expected_output_hex") != output.hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values)

    for text_length in range(6):
        for text in product((32, 33, 65, 97, 98, 126), repeat=text_length):
            add((text_length, *text))

    rng = random.Random(20261015)
    for _ in range(512):
        text_length = rng.randrange(129)
        text = [rng.randrange(32, 127) for _ in range(text_length)]
        add((text_length, *text))

    invalid_inputs = [
        (), (-1,), (513,), (1,), (0, 97), (2, 97), (1, 31), (1, 127),
        (1, 128), (1, -1), (I64_MIN,), (I64_MAX,),
        (512, *([97] * 511)),
    ]
    for values in invalid_inputs:
        add(values)

    records = sorted(cases.items(), key=lambda item: (len(item[0]), item[0]))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)}{suffix} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True,
                             text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"byte-output C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("byte-output checker did not consume the full oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result, expected_output_bytes = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or record["measurement"]["result_checksum"] != fnv1a(expected_output_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM,
        "language": language,
        "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "workload_records": len(records),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output),
        "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/w/wave_string")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "wave-string-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language,
                                args.elisa_compiler, data, case_count, workload): language
                for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language,
                          "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else:
                print(f"PASS {ALGORITHM}/{language}: {case_count} oracle inputs, "
                      f"{result['workload_records']} workload records", flush=True)
            results.append(result)
    report = {
        "algorithm": ALGORITHM,
        "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(),
        "all_passed": len(results) == len(args.languages)
                      and all(result["status"] == "passed" for result in results),
        "corpus_sha256": sha256_file(corpus_path),
        "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda result: result["language"]),
    }
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
