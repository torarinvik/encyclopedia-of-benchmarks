#!/usr/bin/env python3
"""Verify bounded geofence predicate ports against its Haversine oracle."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json, random, subprocess, sys
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from geofence_oracle import expected_result
from run_i64_array_scalar import encode_case

ALGORITHM = "geofence"

def make_corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = tuple(encode_case(case, ALGORITHM)); result = expected_result(values)
        if result != case["expected_result"]: raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = result
    rng = random.Random(20261016)
    for _ in range(300):
        vals = (rng.randint(-90_000_000, 90_000_000), rng.randint(-180_000_000, 180_000_000),
                rng.randint(-90_000_000, 90_000_000), rng.randint(-180_000_000, 180_000_000),
                rng.randint(-1000, 30_000_000_000))
        cases[vals] = expected_result(vals)
    malformed = [(), (0,), (0,0,0,0), (0,0,0,0,0,0),
                 (90_000_001,0,0,0,1000), (0,-180_000_001,0,0,1000),
                 (0,0,0,0,-1_000_001), (0,0,0,0,30_000_000_001)]
    for vals in malformed: cases[tuple(vals)] = expected_result(vals)
    lines = [f"{len(cases)}\n"]
    for vals, result in sorted(cases.items()):
        lines.append(f"{len(vals)} {result}" + (" " + " ".join(map(str, vals)) if vals else "") + "\n")
    return "".join(lines), len(cases)

def verify(lang: str, directory: Path, compiler: str | None, data: str, count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, lang, directory, compiler=compiler if lang == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checked = subprocess.run([manifest["binaries"]["i64_array_scalar_check"]["path"]],
                             input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode or json.loads(checked.stdout).get("cases_checked") != count:
        raise RuntimeError(f"oracle checker failed: {checked.stderr}")
    output = directory / "verification-records.jsonl"; output.unlink(missing_ok=True)
    rec = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                          "--build-manifest", str(directory / "build.json"), "--samples", "1",
                          "--warmups", "0", "--repetitions", "1", "--output", str(output)],
                         cwd=ROOT, capture_output=True, text=True, timeout=180)
    if rec.returncode: raise RuntimeError(f"workload recorder failed: {rec.stdout}\n{rec.stderr}")
    records = [json.loads(x) for x in output.read_text().splitlines()]
    if len(records) != len(workload["cases"]): raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
        if (record["algorithm"] != ALGORITHM or record["implementation"]["language"] != lang
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"workload provenance/result mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": lang, "status": "passed", "oracle_cases": count,
            "workload_records": len(records), "source_sha256": manifest["source_sha256"],
            "build_manifest_sha256": sha256_file(directory / "build.json")}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS)); parser.add_argument("--elisa-compiler"); parser.add_argument("--jobs", type=int, default=3); parser.add_argument("--build-dir", type=Path, default=ROOT / "build/geofence_verify"); args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages): parser.error("jobs must be positive and languages unique")
    workload = json.loads((ROOT / "benchmarks/g/geofence/workload.json").read_text()); data, count = make_corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True); (args.build_dir / "geofence-corpus.txt").write_text(data)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        tasks = {pool.submit(verify, lang, args.build_dir / lang, args.elisa_compiler, data, count, workload): lang for lang in args.languages}
        for task in as_completed(tasks):
            lang = tasks[task]
            try: results.append(task.result()); print(f"PASS {ALGORITHM}/{lang}: {count} oracle cases, {len(workload['cases'])} workloads", flush=True)
            except Exception as e: failures.append({"language": lang, "error": str(e)}); print(f"FAIL {ALGORITHM}/{lang}: {e}", file=sys.stderr, flush=True)
    report = {"algorithm": ALGORITHM, "all_passed": not failures, "oracle_cases": count, "results": sorted(results, key=lambda x: x["language"]), "failures": failures}
    path = args.build_dir / "geofence-verification.json"; path.write_text(json.dumps(report, indent=2) + "\n"); print(f"verification report: {path}")
    return 0 if not failures and len(results) == len(args.languages) else 1
if __name__ == "__main__": raise SystemExit(main())
