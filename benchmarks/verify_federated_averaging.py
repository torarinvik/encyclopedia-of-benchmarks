#!/usr/bin/env python3
"""Focused verifier for the bounded federated averaging benchmark."""
from __future__ import annotations
import argparse
import json
import random
import subprocess
import sys
from pathlib import Path

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from federated_averaging_oracle import expected_result
from run_i64_array_float64 import result_matches, resolve_tolerances


def make_corpus(workload: dict, rng: random.Random) -> tuple[str, int]:
    cases: dict[tuple[int, ...], float] = {}
    for case in workload["cases"]:
        values = tuple(case["input_values"])
        result = expected_result(values)
        abs_tol, rel_tol = resolve_tolerances(workload)
        if not result_matches(result, case["expected_result"], abs_tol, rel_tol):
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = case["expected_result"]
    # Deterministically exercise valid sizes and invalid count, lengths, weights and ranges.
    for _ in range(100):
        count = rng.randint(1, 8)
        weights = [rng.randint(0, 1000) for _ in range(count)]
        if not any(weights):
            weights[rng.randrange(count)] = 1
        values = [rng.randint(-1000, 1000) for _ in range(count)]
        row = tuple([count, *weights, *values])
        cases[row] = expected_result(row)
    for row in ((0,), (9,), (2, 1, 1, 4), (2, -1, 2, 3, 4),
                (2, 0, 0, 3, 4), (1, 1, 1001), (1, 1, 1001, 0)):
        cases[row] = expected_result(row)
    abs_tol, rel_tol = resolve_tolerances(workload)
    lines = [str(len(cases)) + "\n"]
    for values, result in sorted(cases.items()):
        tail = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} 0 {result:.17g} {rel_tol:.17g} {abs_tol:.17g}{tail}\n")
    return "".join(lines), len(cases)


def verify(language: str, outdir: Path, compiler: str | None, data: str,
           count: int, workload: dict) -> dict:
    manifest = build("federated_averaging", language, outdir,
                     compiler=compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_float64")
    checker = manifest["binaries"]["i64_array_float64_check"]["path"]
    check = subprocess.run([checker], input=data, text=True, capture_output=True, timeout=180)
    if check.returncode or json.loads(check.stdout).get("cases_checked") != count:
        raise RuntimeError(f"oracle checker failed: {check.stderr}")
    record_path = outdir / "verification-records.jsonl"
    record_path.unlink(missing_ok=True)
    rec = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_float64.py"),
                          "--build-manifest", str(outdir / "build.json"), "--samples", "1",
                          "--warmups", "0", "--repetitions", "1", "--output", str(record_path)],
                         cwd=ROOT, capture_output=True, text=True, timeout=180)
    if rec.returncode:
        raise RuntimeError(f"workload recorder failed: {rec.stdout}\n{rec.stderr}")
    records = [json.loads(x) for x in record_path.read_text().splitlines()]
    abs_tol, rel_tol = resolve_tolerances(workload)
    if len(records) != len(workload["cases"]):
        raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        actual = float(record["measurement"]["observed_result"])
        if (record["algorithm"] != "federated_averaging"
                or record["implementation"]["language"] != language
                or not result_matches(actual, case["expected_result"], abs_tol, rel_tol)):
            raise RuntimeError(f"workload result/provenance mismatch: {case['id']}")
    return {"algorithm":"federated_averaging", "language":language, "status":"passed",
            "oracle_cases":count, "workload_records":len(records),
            "source_sha256":manifest["source_sha256"],
            "build_manifest_sha256":sha256_file(outdir / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/federated_averaging_verify")
    args = parser.parse_args()
    workload = json.loads((ROOT / "benchmarks/f/federated_averaging/workload.json").read_text())
    data, count = make_corpus(workload, random.Random(20261016))
    args.build_dir.mkdir(parents=True, exist_ok=True)
    (args.build_dir / "federated_averaging-corpus.txt").write_text(data)
    results = []
    for lang in args.languages:
        result = verify(lang, args.build_dir / lang, args.elisa_compiler, data, count, workload)
        results.append(result)
        print(f"PASS federated_averaging/{lang}: {count} oracle arrays, {len(workload['cases'])} workload records", flush=True)
    report = {"algorithm":"federated_averaging", "results":results}
    path = args.build_dir / "federated_averaging-verification.json"
    path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"verification report: {path}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
