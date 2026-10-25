#!/usr/bin/env python3
"""Check WikiSort ports against bounded arrays and the recorded workload."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import json
from pathlib import Path
import platform
import random
import shlex
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from wikisort_oracle import MAXIMUM_LENGTH, generated_values


ALGORITHM = "wikisort"
PINNED_COMMIT = "de24bdf561f4eaad7f37685641fa301f2b8b4bc3"
WORKLOAD_PATH = ROOT / "benchmarks" / "w" / "wikisort" / "workload.json"


def validate_workload(workload: dict) -> None:
    source_url = (
        f"https://github.com/embench/embench-iot/blob/{PINNED_COMMIT}"
        "/src/wikisort/libwikisort.c"
    )
    lengths = [0, 16, 32, 64, 400, 1024, 2048]
    generation = {
        "kind": "modular_affine", "multiplier": 48271, "modulus": 2000003,
        "offset": 1000001,
        "formula": "values[index] = ((index * 48271) mod 2000003) - 1000001",
    }
    if (set(workload) != {"schema_version", "id", "algorithm", "abi", "pinned_source",
                          "profile", "scratch_elements_extra", "input", "measurement", "oracle"}
            or workload.get("schema_version") != 1
            or workload.get("id") != "embench-iot-wikisort-bounded-i64-array-v1"
            or workload.get("algorithm") != ALGORITHM
            or workload.get("abi") != "mutable_i64_with_scratch"
            or workload.get("pinned_source") != {
                "repository": "embench/embench-iot", "commit": PINNED_COMMIT,
                "path": "src/wikisort/libwikisort.c", "symbol": "WikiSort",
                "url": source_url, "declared_license": "GPL-3.0-or-later",
                "original_algorithm_note": "The source attributes WikiSort to BonzaiThePenguin/WikiSort and says the original was placed in the public domain.",
            }
            or workload.get("profile") != {
                "maximum_length": MAXIMUM_LENGTH, "initial_run_size": 16,
                "cache_capacity": 512,
                "small_merge": "stable buffered merge when the left run fits in cache",
                "large_merge": "bounded block rotation with lower-bound partitions and cache-assisted rotations",
            }
            or workload.get("scratch_elements_extra") != 0
            or workload.get("input") != {"lengths": lengths, "generation": generation}
            or workload.get("measurement") != {
                "timer": "clock()", "comparison_model": "sort_call",
                "warmup_rounds": 2, "sample_count": 7,
                "scratch_allocation_timed": False,
            }
            or workload.get("oracle") != {
                "path": "benchmarks/wikisort_oracle.py",
                "operation": "compare the full result with the ascending stable reference order",
            }):
        raise ValueError("wikisort workload metadata differs from the pinned bounded profile")

    package = ROOT / "benchmarks" / "w" / "wikisort"
    readme = (package / "README.md").read_text(encoding="utf-8")
    license_text = (package / "LICENSE.txt").read_text(encoding="utf-8")
    if (source_url not in readme or "GPL-3.0-or-later" not in readme
            or "BonzaiThePenguin/WikiSort" not in readme
            or "block-rotation fallback" not in readme
            or "GNU GENERAL PUBLIC LICENSE" not in license_text):
        raise ValueError("wikisort README or GPL/public-domain attribution is incomplete")
    for relative in (
            "c/w/wikisort.c", "c3/w/wikisort.c3", "cpp/w/wikisort.cpp",
            "elisa/w/wikisort.elisa", "nim/w/wikisort.nim", "odin/w/wikisort.odin",
            "rust/w/wikisort.rs", "v/w/wikisort.v", "zig/w/wikisort.zig"):
        if not (ROOT / relative).is_file():
            raise ValueError(f"wikisort port is missing: {relative}")


def corpus() -> tuple[str, int]:
    lengths = (0, 1, 2, 15, 16, 17, 31, 32, 33, 63, 64, 65, 255, 256, 257,
               399, 400, 401, 511, 512, 513, 1023, 1024, 1025,
               MAXIMUM_LENGTH - 1, MAXIMUM_LENGTH)
    arrays: set[tuple[int, ...]] = set()
    for length in lengths:
        values = generated_values(length)
        arrays.update((tuple(values), tuple(reversed(values)), tuple(sorted(values))))
        arrays.add(tuple((index % 7) - 3 for index in range(length)))
        arrays.add(tuple((length - index) % 11 for index in range(length)))

    extremes = (-(1 << 63), (1 << 63) - 1, -1, 0, 1)
    arrays.update((extremes, tuple(reversed(extremes)), extremes * 80))
    rng = random.Random(0x57494B49)
    for length in (63, 257, 513, 1024, MAXIMUM_LENGTH):
        arrays.add(tuple(rng.randint(-(1 << 63), (1 << 63) - 1)
                         for _ in range(length)))

    ordered = sorted(arrays, key=lambda values: (len(values), values))
    lines = [f"{len(ordered)}\n"]
    lines.extend(f"{len(values)}" + (" " + " ".join(map(str, values)) if values else "") + "\n"
                 for values in ordered)
    return "".join(lines), len(ordered)


def workload_values(length: int, generation: dict) -> tuple[int, ...]:
    if generation.get("kind") != "modular_affine":
        raise ValueError("wikisort requires modular_affine workload inputs")
    return tuple((index * int(generation["multiplier"])) % int(generation["modulus"])
                 - int(generation["offset"]) for index in range(length))


def sorted_checksum(values: tuple[int, ...]) -> int:
    checksum = 14695981039346656037
    mask = (1 << 64) - 1
    for value in sorted(values):
        checksum = ((checksum ^ (value & mask)) * 1099511628211) & mask
    return checksum


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="sort")
    checker = manifest["binaries"]["sort_checker"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"C ABI sort check failed: {checked.stderr}")
    if json.loads(checked.stdout).get("cases_checked") != case_count:
        raise RuntimeError("sort checker did not consume the full WikiSort corpus")

    records_path = directory / "verification-records.jsonl"
    records_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks" / "run_sort.py"),
         "--algorithm", ALGORITHM, "--language", language,
         "--source", str(ROOT / manifest["source_path"]),
         "--executable", manifest["binaries"]["sort_runner"]["path"],
         "--compiler", manifest["compiler"],
         "--compiler-version", manifest["compiler_version"],
         "--build-flags=" + manifest["build_flags"],
         "--build-command", "\n".join(shlex.join(command) for command in manifest["commands"]),
         "--samples", "1", "--warmups", "0", "--output", str(records_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120,
    )
    if recorded.returncode:
        raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")

    records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
    lengths = workload["input"]["lengths"]
    if len(records) != len(lengths):
        raise RuntimeError("sort recorder emitted an unexpected number of records")
    generation = workload["input"]["generation"]
    for length_value, record in zip(lengths, records):
        length = int(length_value)
        expected_checksum = sorted_checksum(workload_values(length, generation))
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_length"] != length
                or record["measurement"]["observed_result"] != length
                or record["measurement"]["result_checksum"] != expected_checksum
                or len(record["measurement"]["samples_ns"]) != 1):
            raise RuntimeError(f"workload, checksum, or provenance mismatch at length {length}")
    return {
        "algorithm": ALGORITHM, "language": language, "status": "passed",
        "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"],
        "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
        "workload_records": len(records),
        "workload_sha256": sha256_file(WORKLOAD_PATH),
        "build_manifest": str(directory / "build.json"),
        "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(records_path),
        "recorder_output_sha256": sha256_file(records_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler", help="Custom Elisa compiler executable path")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build" / "wikisort")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    try:
        workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
        validate_workload(workload)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        parser.error(str(error))
    data, case_count = corpus()
    build_dir = args.build_dir.resolve()
    build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {
            executor.submit(verify, language, build_dir / language, args.elisa_compiler,
                            data, case_count, workload): language
            for language in args.languages
        }
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} arrays, "
                  f"{result['workload_records']} workload records", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
