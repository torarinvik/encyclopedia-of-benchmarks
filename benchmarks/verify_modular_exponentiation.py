#!/usr/bin/env python3
"""Verify modular exponentiation ports against Python's three-argument pow oracle."""
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
from run_i64_array_scalar import encode_case

ALGORITHM = "modular_exponentiation"
I32_MIN, I32_MAX = -(2**31), 2**31 - 1

def oracle(values: list[int]) -> int:
    if len(values) != 3 or any(type(value) is not int for value in values): return -1
    base, exponent, modulus = values
    if not I32_MIN <= base <= I32_MAX or not 0 <= exponent <= I32_MAX or not 1 <= modulus <= I32_MAX: return -1
    return pow(base, exponent, modulus)

def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    def include(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))
    for base, exponent, modulus in product(range(-8, 9), range(13), range(1, 14)):
        include((base, exponent, modulus))
    rng = random.Random(20261014)
    for _ in range(768):
        include((rng.randint(I32_MIN, I32_MAX), rng.randint(0, I32_MAX), rng.randint(1, I32_MAX)))
    for values in [[], [2], [2, 3], [2, 3, 5, 7], [I32_MIN - 1, 0, 7],
                   [I32_MAX + 1, 0, 7], [2, -1, 7], [2, I32_MAX + 1, 7],
                   [2, 3, 0], [2, 3, -1], [2, 3, I32_MAX + 1]]:
        include(values)
    for case in workload["cases"]:
        values = encode_case(case, ALGORITHM)
        if oracle(values) != case["expected_result"]: raise ValueError(f"workload oracle mismatch: {case['id']}")
        include(values)
    records = sorted(cases.items())
    lines = [f"{len(records)}\n"]
    for values, expected in records:
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(records)

def verify(language: str, directory: Path, elisa_compiler: str | None, data: str,
           case_count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory, compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode: raise RuntimeError(f"C ABI oracle check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count: raise RuntimeError("incomplete oracle corpus")
    output = directory / "verification-records.jsonl"; output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1", "--warmups", "0",
        "--repetitions", "1", "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode: raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]): raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM); expected = oracle(values)
        if (record["algorithm"] != ALGORITHM or record["implementation"]["language"] != language
            or record["implementation"]["source_sha256"] != manifest["source_sha256"]
            or record["workload"]["input_length"] != len(values) or record["workload"]["input_values"] != values
            or record["workload"]["expected_result"] != expected or record["measurement"]["observed_result"] != expected):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"], "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/m/modular_exponentiation/workload.json"),
        "build_manifest": str(directory / "build.json"), "build_manifest_sha256": sha256_file(directory / "build.json"),
        "recorder_output": str(output), "recorder_output_sha256": sha256_file(output)}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path)
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages): parser.error("jobs must be positive and languages must be unique")
    workload_path = ROOT / "benchmarks/m/modular_exponentiation/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = (args.build_dir or ROOT / "build/i64_array_scalar/m/modular_exponentiation").resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "modular-exponentiation-corpus.txt"; corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, lang, directory / lang, args.elisa_compiler, data, case_count, workload): lang for lang in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try: result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else: print(f"PASS {ALGORITHM}/{language}: {case_count} scalar-array cases, {result['workload_records']} workload records", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(), "all_passed": len(results) == len(args.languages) and all(r["status"] == "passed" for r in results),
        "corpus_sha256": sha256_file(corpus_path), "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"; report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1
if __name__ == "__main__": raise SystemExit(main())
