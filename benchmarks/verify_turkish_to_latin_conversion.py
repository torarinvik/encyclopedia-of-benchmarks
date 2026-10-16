#!/usr/bin/env python3
"""Verify Turkish-to-Latin UTF-8 conversion in every target language."""

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

ALGORITHM = "turkish_to_latin_conversion"
MAX_TEXT_BYTES = 1024
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
REPLACEMENTS = {
    "ı": "i", "İ": "I", "ü": "u", "Ü": "U", "ö": "o", "Ö": "O",
    "ş": "s", "Ş": "S", "ç": "c", "Ç": "C", "ğ": "g", "Ğ": "G",
}


def oracle(values: tuple[int, ...] | list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_TEXT_BYTES + 1
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    byte_length = values[0]
    if not 0 <= byte_length <= MAX_TEXT_BYTES or len(values) != byte_length + 1:
        return -1, b""
    payload = values[1:]
    if any(not 0 <= value <= 255 for value in payload):
        return -1, b""
    try:
        text = bytes(payload).decode("utf-8", errors="strict")
    except UnicodeDecodeError:
        return -1, b""
    transformed = text.translate(str.maketrans(REPLACEMENTS)).encode("utf-8")
    if capacity is not None and len(transformed) > capacity:
        return -2, b""
    return len(transformed), transformed


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[tuple[int, ...], int], tuple[int, bytes]] = {}

    def add(values: tuple[int, ...] | list[int], capacity: int | None = None) -> None:
        packed = tuple(values)
        expected_capacity = 1024 if capacity is None else capacity
        result = oracle(packed, expected_capacity)
        independent = oracle(packed)
        runner = expected_output(list(packed), ALGORITHM)
        if runner != independent:
            raise ValueError(f"independent and recorder oracles disagree for input prefix {packed[:12]}")
        cases[(packed, expected_capacity)] = result

    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = oracle(values)
        if (case.get("input_length") != len(values)
                or case.get("expected_result") != result
                or case.get("expected_output_hex") != output.hex()):
            raise ValueError(f"published workload disagrees with oracle: {case['id']}")
        add(values)

    characters = [*REPLACEMENTS.keys(), "a", "I", "z", " ", "!", "1", "ñ", "水", "🙂"]
    for char_count in range(4):
        for text in product(characters, repeat=char_count):
            add((len("".join(text).encode("utf-8")), *"".join(text).encode("utf-8")))

    rng = random.Random(20261015)
    for _ in range(512):
        count = rng.randrange(129)
        text = "".join(rng.choice(characters) for _ in range(count))
        encoded = text.encode("utf-8")
        if len(encoded) > MAX_TEXT_BYTES:
            continue
        add((len(encoded), *encoded))

    for malformed in (
        b"\x80", b"\xc0\xaf", b"\xc4", b"\xe2\x82", b"\xed\xa0\x80",
        b"\xf4\x90\x80\x80", b"\xf0\x80\x80\x80", b"\xc3A",
    ):
        add((len(malformed), *malformed))
    for values in (
        (), (-1,), (1025,), (2, 65), (1, 256), (1, -1),
        (I64_MIN,), (I64_MAX,), (1024, *([65] * 1023)),
    ):
        add(values)

    sample_text = "ışık".encode("utf-8")
    sample = (len(sample_text), *sample_text)
    output_length = oracle(sample)[0]
    if output_length > 0:
        add(sample, capacity=output_length - 1)
    add((0,), capacity=0)

    records = sorted(cases.items(), key=lambda item: (len(item[0][0]), item[0][0], item[0][1]))
    lines = [f"{len(records)}\n"]
    for (values, capacity), (result, output) in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        encoded = output.hex() if output else "-"
        lines.append(f"{len(values)} {result} {len(output)} {capacity}{suffix} {encoded}\n")
    return "".join(lines), len(records)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=240)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI checker failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full oracle corpus")

    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"),
        "--samples", "1", "--warmups", "0", "--repetitions", "1",
        "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=240)
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        result, output_bytes = oracle(values)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != len(values)
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != result
                or record["measurement"]["observed_result"] != result
                or record["measurement"]["result_checksum"] != fnv1a(output_bytes)
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
        "workload_records": len(records), "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output), "recorder_output_sha256": sha256_file(output),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/t/turkish_to_latin_conversion")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")

    workload_path = ROOT / "benchmarks/t/turkish_to_latin_conversion/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "turkish-to-latin-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, directory / language, args.elisa_compiler,
                            data, case_count, workload): language
            for language in args.languages
        }
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
