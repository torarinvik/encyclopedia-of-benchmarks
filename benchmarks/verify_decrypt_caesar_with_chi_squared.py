#!/usr/bin/env python3
"""Verify the chi-squared Caesar decoder ports against the Python oracle."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from caesar_chi_squared_oracle import expected_output

ALGORITHM = "decrypt_caesar_with_chi_squared"
FAMILY = "i64_array_bytes_output"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def add(raw: bytes, malformed: bool = False) -> None:
        values = tuple([len(raw), *raw])
        result, output = expected_output(list(values))
        if malformed:
            values = (len(raw) + 1, *raw)
            result, output = expected_output(list(values))
        cases[values] = result, output

    for size in range(27):
        add(bytes([97]) * size)
        add(bytes((97 + (index * 11) % 26) for index in range(size)))
    for byte in range(128):
        add(bytes([byte]))
    rng = random.Random(20261016)
    for _ in range(384):
        add(bytes(rng.randrange(128) for _ in range(rng.randrange(129))))
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result, output = expected_output(list(values))
        if result != case["expected_result"] or output.hex() != case["expected_output_hex"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = result, output
    add(b"", malformed=True)
    add(bytes([65]) * 3)

    lines = [f"{len(cases)}\n"]
    for values, (result, output) in sorted(cases.items()):
        encoded = output.hex() if output else "-"
        value_text = "" if not values else " " + " ".join(map(str, values))
        # The checker reads its null-input flag after the expected output size.
        lines.append(f"{len(values)} {result} {len(output)} 0{value_text} {encoded}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family=FAMILY)
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode or json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError(f"byte-output ABI checker failed: {checked.stderr or checked.stdout}")
    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output_path),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    rows = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(rows) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, row in zip(workload["cases"], rows):
        result, _ = expected_output(case["input_values"])
        if (row["algorithm"] != ALGORITHM
                or row["implementation"]["language"] != language
                or row["implementation"]["source_sha256"] != manifest["source_sha256"]
                or row["workload"]["input_values"] != case["input_values"]
                or row["workload"]["expected_result"] != result
                or row["measurement"]["observed_result"] != result
                or len(row["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"record/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(rows), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/decrypt_caesar_with_chi_squared")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    workload = json.loads((ROOT / "benchmarks/d/decrypt_caesar_with_chi_squared/workload.json").read_text())
    data, count = corpus(workload)
    (directory / "chi-squared-caesar-corpus.txt").write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {executor.submit(verify, lang, directory / lang, args.elisa_compiler,
                                   data, count, workload): lang for lang in args.languages}
        for future in as_completed(futures):
            lang = futures[future]
            try:
                results.append(future.result())
                print(f"PASS {ALGORITHM}/{lang}: {count} oracle inputs", flush=True)
            except Exception as error:
                failures.append((lang, str(error)))
                print(f"FAIL {ALGORITHM}/{lang}: {error}", file=sys.stderr, flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "all_passed": not failures,
              "results": sorted(results, key=lambda item: item["language"]), "failures": failures}
    (directory / "verification.json").write_text(json.dumps(report, indent=2) + "\n")
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
