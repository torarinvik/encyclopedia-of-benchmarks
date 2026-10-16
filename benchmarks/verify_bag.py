#!/usr/bin/env python3
"""Verify portable bag operations against the shared multiset contract."""

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

from bag_oracle import expected_output
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "bag"
WORKLOAD_PATH = ROOT / "benchmarks/b/bag/workload.json"


def corpus(workload: dict) -> tuple[str, int, dict[tuple[int, ...], tuple[int, bytes]]]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def include(values: tuple[int, ...], declared: tuple[int, str] | None = None) -> None:
        result = expected_output(list(values))
        if declared is not None and (result[0] != declared[0] or result[1].hex() != declared[1]):
            raise ValueError("published workload differs from the bag oracle")
        cases[values] = result

    for case in workload["cases"]:
        include(tuple(case["input_values"]),
                (case["expected_result"], case["expected_output_hex"]))

    rng = random.Random(20261015)
    for _ in range(512):
        insert_count = rng.randrange(129)
        inserted = [rng.randrange(-(1 << 31), 1 << 31) for _ in range(insert_count)]
        if inserted and rng.random() < 0.75:
            for _ in range(rng.randrange(1, min(insert_count, 8) + 1)):
                inserted[rng.randrange(insert_count)] = inserted[rng.randrange(insert_count)]
        query_count = rng.randrange(65)
        queries = [rng.choice(inserted) if inserted and rng.random() < 0.5
                   else rng.randrange(-(1 << 31), 1 << 31) for _ in range(query_count)]
        include((insert_count, *inserted, query_count, *queries))

    for invalid in ((), (0,), (-1, 0), (129, 0), (1, 7), (0, 1, 4),
                    (1, 7, 2, 7), (1, 7, 0, 8), (1, 1 << 31, 0),
                    (1, -(1 << 31) - 1, 0), (0, 1, 1 << 31),
                    (0, 1, -(1 << 31) - 1), (0, 65),
                    (0, 0, 99), (0, 0, 0, 123),
                    (1 << 63, 0), (0, -(1 << 63))):
        include(invalid)

    records = sorted(cases.items())
    capacity_case = (3, 4, 4, 5, 2, 4, 7)
    records.append((capacity_case, (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {output.hex() if output else '-'}\n")
    return "".join(lines), len(records), dict(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int,
           cases: dict[tuple[int, ...], tuple[int, bytes]], workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"bag ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full bag corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"bag workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of bag workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        expected_result, expected_bytes = cases[values]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["expected_result"] != expected_result
                or record["measurement"]["observed_result"] != expected_result
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path,
                        default=ROOT / "build/i64_array_bytes_output/bag")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages):
        parser.error("jobs must be between 1 and the selected language count")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    checker_input, case_count, cases = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language, args.build_dir / language,
                            args.elisa_compiler, checker_input, case_count, cases, workload): language
            for language in args.languages
        }
        for future in as_completed(futures):
            results.append(future.result())
    results.sort(key=lambda record: record["language"])
    report = {"schema_version": 1, "algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": {"system": platform.system(), "release": platform.release(),
                           "machine": platform.machine(), "python": platform.python_version()},
              "oracle_cases_per_language": case_count,
              "workload_records_per_language": len(workload["cases"]), "languages": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "oracle_cases_per_language": case_count,
                      "languages": [record["language"] for record in results],
                      "report": str(report_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
