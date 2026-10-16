#!/usr/bin/env python3
"""Verify the fixed 12-character geohash encoder in all native ports."""
from __future__ import annotations
import argparse, json, random, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from geohash_oracle import expected_output

ALGORITHM = "geohash"
MASK64 = (1 << 64) - 1
def output_checksum(data: bytes) -> int:
    h = 0xCBF29CE484222325
    for byte in data: h = ((h ^ byte) * 0x100000001B3) & MASK64
    return h

def make_cases(workload: dict) -> dict[tuple[int, ...], tuple[int, bytes]]:
    cases = {}
    for case in workload["cases"]:
        values = tuple(case["input_values"]); result, output = expected_output(values)
        if result != case["expected_result"] or output.hex() != case["expected_output_hex"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = (result, output)
    rng = random.Random(20261016)
    for _ in range(300):
        vals = (rng.randint(-90_000_000, 90_000_000), rng.randint(-180_000_000, 180_000_000))
        cases[vals] = expected_output(vals)
    for vals in ((), (0,), (0, 0, 0), (90_000_001, 0), (0, -180_000_001)):
        cases[vals] = expected_output(vals)
    return cases

def checker_data(cases: dict[tuple[int, ...], tuple[int, bytes]]) -> str:
    rows = [str(len(cases))]
    for i, (values, (count, output)) in enumerate(sorted(cases.items())):
        head = f"{len(values)} {count} {len(output)}"
        rows.append(head + " 0" + (" " + " ".join(map(str, values)) if values else "")
                    + " " + (output.hex() if output else "-") )
    return "\n".join(rows) + "\n"

def verify(lang: str, directory: Path, compiler: str | None, workload: dict,
           cases: dict[tuple[int, ...], tuple[int, bytes]], data: str) -> dict:
    manifest = build(ALGORITHM, lang, directory, compiler=compiler if lang == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checked = subprocess.run([manifest["binaries"]["i64_array_bytes_output_check"]["path"]],
                             input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode or json.loads(checked.stdout).get("cases_checked") != len(cases):
        raise RuntimeError(f"oracle checker failed: {checked.stderr}")
    output_path = directory / "verification-records.jsonl"; output_path.unlink(missing_ok=True)
    rec = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
                          "--build-manifest", str(directory / "build.json"), "--samples", "1",
                          "--warmups", "0", "--repetitions", "1", "--output", str(output_path)],
                         cwd=ROOT, capture_output=True, text=True, timeout=180)
    if rec.returncode: raise RuntimeError(f"workload recorder failed: {rec.stdout}\n{rec.stderr}")
    records = [json.loads(x) for x in output_path.read_text().splitlines()]
    if len(records) != len(workload["cases"]): raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = case["input_values"]
        if (record["algorithm"] != ALGORITHM or record["implementation"]["language"] != lang
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]
                or record["measurement"]["result_checksum"] != output_checksum(bytes.fromhex(case["expected_output_hex"]))):
            raise RuntimeError(f"workload provenance/result mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": lang, "status": "passed",
            "oracle_cases": len(cases), "workload_records": len(records),
            "source_sha256": manifest["source_sha256"],
            "build_manifest_sha256": sha256_file(directory / "build.json")}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS)); parser.add_argument("--elisa-compiler"); parser.add_argument("--jobs", type=int, default=3); parser.add_argument("--build-dir", type=Path, default=ROOT / "build/geohash_verify"); args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages): parser.error("jobs must be positive and languages unique")
    workload = json.loads((ROOT / "benchmarks/g/geohash/workload.json").read_text()); cases = make_cases(workload); data = checker_data(cases)
    args.build_dir.mkdir(parents=True, exist_ok=True); (args.build_dir / "geohash-corpus.txt").write_text(data)
    results, failures = [], []
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        tasks = {pool.submit(verify, lang, args.build_dir / lang, args.elisa_compiler, workload, cases, data): lang for lang in args.languages}
        for task in as_completed(tasks):
            lang = tasks[task]
            try: results.append(task.result()); print(f"PASS {ALGORITHM}/{lang}: {len(cases)} oracle cases, {len(workload['cases'])} workloads", flush=True)
            except Exception as e: failures.append({"language": lang, "error": str(e)}); print(f"FAIL {ALGORITHM}/{lang}: {e}", file=sys.stderr, flush=True)
    report = {"algorithm": ALGORITHM, "all_passed": not failures, "oracle_cases": len(cases), "results": sorted(results, key=lambda r:r["language"]), "failures": failures}
    path=args.build_dir/"geohash-verification.json";path.write_text(json.dumps(report,indent=2)+"\n");print(f"verification report: {path}")
    return 0 if not failures and len(results)==len(args.languages) else 1
if __name__ == "__main__": raise SystemExit(main())
