#!/usr/bin/env python3
"""Verify the linked deque operation trace in every target language."""
from __future__ import annotations

import argparse
import json
import random
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from linked_deque_oracle import expected_result

ALGORITHM = "linked_deque"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = case["input_values"]
        expected = expected_result(values)
        if case["input_length"] != len(values) or case["expected_result"] != expected:
            raise ValueError(f"workload disagrees with oracle: {case['id']}")
        cases[tuple(values)] = expected
    rng = random.Random(20261016)
    for _ in range(3000):
        count = rng.randrange(1, 11)
        values: list[int] = []
        for _ in range(count):
            op = rng.randrange(7)
            arg = rng.randrange(-15, 16) if op < 2 else 0
            values.extend((op, arg))
        cases[tuple(values)] = expected_result(values)
    lines = [f"{len(cases)}\n"]
    for values, result in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int, workload: dict) -> dict:
    shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
             if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar", extra_link_sources=shims)
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode:
        raise RuntimeError(f"scalar C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full corpus")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    run = subprocess.run([
        sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1",
        "--warmups", "0", "--repetitions", "1", "--output", str(output),
    ], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if run.returncode:
        raise RuntimeError(f"recorder/workload check failed: {run.stdout}\n{run.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected record count")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"recorder mismatch for {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "workload_records": len(records),
            "source_sha256": manifest["source_sha256"],
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output_sha256": sha256_file(output)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/linked_deque")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/l/linked_deque/workload.json").read_text(encoding="utf-8"))
    data, count = corpus(workload)
    root = args.build_dir.resolve()
    root.mkdir(parents=True, exist_ok=True)
    (root / "linked_deque-corpus.txt").write_text(data, encoding="utf-8")
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs = {pool.submit(verify, lang, root / lang, args.elisa_compiler, data, count, workload): lang
                for lang in args.languages}
        for job in as_completed(jobs):
            lang = jobs[job]
            try:
                result = job.result()
                results.append(result)
                print(f"PASS {lang}: {count} oracle cases, {result['workload_records']} workload records", flush=True)
            except Exception as error:
                failures.append((lang, str(error)))
                print(f"FAIL {lang}: {error}", file=sys.stderr, flush=True)
    report = {"algorithm": ALGORITHM, "results": sorted(results, key=lambda r: r["language"]),
              "failures": failures}
    (root / "verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
