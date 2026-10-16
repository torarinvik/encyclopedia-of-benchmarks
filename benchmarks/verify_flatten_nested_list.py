#!/usr/bin/env python3
"""Focused verifier for recursive nested-list flattening ports."""
from __future__ import annotations
import argparse
import json
import random
import subprocess
import sys
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from flatten_nested_list_oracle import OPEN, CLOSE, expected_result


def corpus(workload: dict) -> tuple[str, int]:
    cases = {tuple(case["input_values"]): int(case["expected_result"])
             for case in workload["cases"]}
    for values, expected in cases.items():
        if expected_result(list(values)) != expected:
            raise ValueError("published workload disagrees with flatten_nested_list oracle")
    rng = random.Random(20261016)
    for _ in range(128):
        depth = rng.randint(1, 16)
        tokens = [OPEN] * depth
        for _ in range(rng.randint(0, 12)):
            tokens.append(rng.randint(-1_000_000, 1_000_000))
            if rng.random() < 0.45 and depth < 16 and len(tokens) + depth < 240:
                nested = rng.randint(1, min(4, 16 - depth))
                tokens.extend([OPEN] * nested)
                tokens.extend(rng.randint(-1_000_000, 1_000_000)
                              for _ in range(rng.randint(0, 3)))
                tokens.extend([CLOSE] * nested)
        tokens.extend([CLOSE] * depth)
        row = tuple(tokens)
        if len(row) <= 255:
            cases[row] = expected_result(list(row))
    malformed = [(), (1,), (CLOSE,), (OPEN, 1), (OPEN, CLOSE, 0),
                 (OPEN, OPEN, CLOSE), tuple([OPEN] * 17 + [CLOSE] * 17),
                 (OPEN, 1_000_001, CLOSE), tuple([OPEN, 0, CLOSE] * 86)]
    for row in malformed:
        cases[row] = expected_result(list(row))
    lines = [f"{len(cases)}\n"]
    for values, expected in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {expected}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, compiler: str | None, data: str,
           count: int, workload: dict) -> dict:
    manifest = build("flatten_nested_list", language, directory,
                     compiler=compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    check = subprocess.run([manifest["binaries"]["i64_array_scalar_check"]["path"]],
                           input=data, text=True, capture_output=True, timeout=180)
    if check.returncode or json.loads(check.stdout).get("cases_checked") != count:
        raise RuntimeError(f"oracle checker failed: {check.stderr}")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    rec = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                          "--build-manifest", str(directory / "build.json"), "--samples", "1",
                          "--warmups", "0", "--repetitions", "1", "--output", str(output)],
                         cwd=ROOT, capture_output=True, text=True, timeout=180)
    if rec.returncode:
        raise RuntimeError(f"workload recorder failed: {rec.stdout}\n{rec.stderr}")
    records = [json.loads(line) for line in output.read_text().splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        if (record["algorithm"] != "flatten_nested_list"
                or record["implementation"]["language"] != language
                or record["workload"]["input_values"] != case["input_values"]
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"workload result/provenance mismatch: {case['id']}")
    return {"algorithm":"flatten_nested_list", "language":language, "status":"passed",
            "oracle_cases":count, "workload_records":len(records),
            "source_sha256":manifest["source_sha256"],
            "build_manifest_sha256":sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/flatten_nested_list_verify")
    args = parser.parse_args()
    workload = json.loads((ROOT / "benchmarks/f/flatten_nested_list/workload.json").read_text())
    data, count = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    (args.build_dir / "flatten_nested_list-corpus.txt").write_text(data)
    results = []
    for language in args.languages:
        result = verify(language, args.build_dir / language, args.elisa_compiler, data, count, workload)
        results.append(result)
        print(f"PASS flatten_nested_list/{language}: {count} oracle arrays, {len(workload['cases'])} workload records", flush=True)
    report = {"algorithm":"flatten_nested_list", "results":results}
    path = args.build_dir / "flatten_nested_list-verification.json"
    path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {path}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
