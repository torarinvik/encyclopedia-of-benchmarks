#!/usr/bin/env python3
"""Verify the bounded logical semantics shared by two Java chained hash maps."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import random
import subprocess
import sys
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from generic_hash_map_oracle import expected_result
from run_i64_array_scalar import encode_case

ALGORITHM = "generic_hash_map"


def make_corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    for case in workload["cases"]:
        values = tuple(encode_case(case, ALGORITHM))
        result = expected_result(values)
        if result != case["expected_result"]:
            raise ValueError(f"workload oracle mismatch: {case['id']}")
        cases[values] = result
    rng = random.Random(20261016)
    for _ in range(300):
        ops: list[tuple[int, int, int]] = []
        keys: list[int] = []
        for _ in range(rng.randint(0, 100)):
            choices = [0, 1, 2, 3, 4]
            if len(keys) >= 64:
                choices = [1, 2, 3, 4]
            op = rng.choice(choices)
            if op == 4:
                ops.append((4, 0, 0))
            else:
                key = rng.choice(keys) if keys and rng.random() < 0.6 else rng.randint(0, 1000)
                if op == 0:
                    ops.append((0, key, rng.randint(-1000000, 1000000)))
                    if key not in keys: keys.append(key)
                else:
                    ops.append((op, key, 0))
                    if op == 2 and key in keys: keys.remove(key)
        values = tuple([len(ops), *(field for item in ops for field in item)])
        cases[values] = expected_result(values)
    for values in ((), (0, 1), (1, 0, 0), (1, 0, 1000001, 1),
                   (1, 1, -1, 0), (1, 2, 0, 1), (1, 3, 0, 1),
                   (1, 4, 1, 0), (129,), (0, 0, 0, 0)):
        cases[tuple(values)] = expected_result(list(values))
    lines = [f"{len(cases)}\n"]
    for values, result in sorted(cases.items()):
        suffix = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result}{suffix}\n")
    return "".join(lines), len(cases)


def verify(language: str, directory: Path, compiler: str | None,
           data: str, count: int, workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar")
    checked = subprocess.run([manifest["binaries"]["i64_array_scalar_check"]["path"]],
                             input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode or json.loads(checked.stdout).get("cases_checked") != count:
        raise RuntimeError(f"oracle checker failed: {checked.stderr}")
    output = directory / "verification-records.jsonl"
    output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
                               "--build-manifest", str(directory / "build.json"), "--samples", "1",
                               "--warmups", "0", "--repetitions", "1", "--output", str(output)],
                              cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text().splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != values
                or record["workload"]["expected_result"] != case["expected_result"]
                or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"workload provenance/result mismatch: {case['id']}")
    return {"algorithm":ALGORITHM,"language":language,"status":"passed","oracle_cases":count,
            "workload_records":len(records),"source_sha256":manifest["source_sha256"],
            "build_manifest_sha256":sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/generic_hash_map_verify")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections unique")
    workload = json.loads((ROOT / "benchmarks/g/generic_hash_map/workload.json").read_text())
    data, count = make_corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    (args.build_dir / "generic_hash_map-corpus.txt").write_text(data)
    results=[]; failures=[]
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        tasks={pool.submit(verify, lang, args.build_dir/lang, args.elisa_compiler,data,count,workload):lang for lang in args.languages}
        for task in as_completed(tasks):
            lang=tasks[task]
            try:
                result=task.result(); results.append(result)
                print(f"PASS {ALGORITHM}/{lang}: {count} oracle traces, {len(workload['cases'])} workload records",flush=True)
            except Exception as error:
                failures.append({"language":lang,"error":str(error)})
                print(f"FAIL {ALGORITHM}/{lang}: {error}",file=sys.stderr,flush=True)
    report={"algorithm":ALGORITHM,"all_passed":not failures,"oracle_cases":count,"results":sorted(results,key=lambda x:x['language']),"failures":failures}
    path=args.build_dir/"generic_hash_map-verification.json";path.write_text(json.dumps(report,indent=2)+"\n")
    print(f"verification report: {path}")
    return 0 if not failures and len(results)==len(args.languages) else 1

if __name__ == "__main__": raise SystemExit(main())
