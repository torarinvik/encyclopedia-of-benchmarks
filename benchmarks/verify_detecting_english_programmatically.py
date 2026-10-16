#!/usr/bin/env python3
"""Verify bounded dictionary-based English detectors in every target language."""
from __future__ import annotations
import argparse, datetime as dt, json, platform, random, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from detecting_english_programmatically_oracle import expected_result
from run_i64_array_scalar import encode_case

ALGORITHM = "detecting_english_programmatically"

def corpus(workload):
    cases = {}
    for case in workload["cases"]:
        values = encode_case(case, ALGORITHM)
        result = expected_result(values)
        if result != case["expected_result"]: raise ValueError(f"workload mismatch: {case['id']}")
        cases[tuple(values)] = result
    rng = random.Random(20261016)
    words = [b"A", b"AT", b"CAT", b"DOG", b"HELLO", b"WORLD"]
    for _ in range(3000):
        d = sorted(set(rng.sample(words, rng.randrange(0, 5))))
        msg = bytes(rng.choice(b"HELLOworld!? \t\n") for _ in range(rng.randrange(0, 20)))
        vals = [len(d)]
        for word in d: vals += [len(word), *word]
        vals += [len(msg), *msg, rng.randrange(101), rng.randrange(101)]
        cases[tuple(vals)] = expected_result(vals)
    lines = [f"{len(cases)}\n"]
    for values, result in sorted(cases.items()):
        lines.append(f"{len(values)} {result} {' '.join(map(str, values))}\n")
    return "".join(lines), len(cases)

def verify(language, directory, compiler, data, count, workload):
    shims = ((ROOT / "benchmarks/harness/elisa_empty_stack_arena_free.c",)
             if language == "elisa" else ())
    manifest = build(ALGORITHM, language, directory, compiler=compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_scalar", extra_link_sources=shims)
    checker = manifest["binaries"]["i64_array_scalar_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=180)
    if checked.returncode or json.loads(checked.stdout)["cases_checked"] != count:
        raise RuntimeError(f"checker failed: {checked.stderr}")
    output = directory / "verification-records.jsonl"; output.unlink(missing_ok=True)
    run = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1", "--warmups", "0",
        "--repetitions", "1", "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if run.returncode: raise RuntimeError(run.stdout + run.stderr)
    records = [json.loads(line) for line in output.read_text().splitlines()]
    if len(records) != len(workload["cases"]): raise RuntimeError("unexpected recorder output count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, ALGORITHM)
        if (record["implementation"]["source_sha256"] != manifest["source_sha256"]
            or record["workload"]["input_values"] != values
            or record["measurement"]["observed_result"] != case["expected_result"]):
            raise RuntimeError(f"record mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": count,
            "workload_records": len(records), "source_sha256": manifest["source_sha256"]}

def main():
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS)); parser.add_argument("--elisa-compiler"); parser.add_argument("--jobs", type=int, default=3); parser.add_argument("--build-dir", type=Path, default=ROOT/"build/detecting_english_programmatically"); args=parser.parse_args()
    workload=json.loads((ROOT/"benchmarks/d/detecting_english_programmatically/workload.json").read_text())
    data,count=corpus(workload); root=args.build_dir.resolve(); root.mkdir(parents=True,exist_ok=True)
    results=[]; failures=[]
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs={pool.submit(verify,lang,root/lang,args.elisa_compiler,data,count,workload):lang for lang in args.languages}
        for job in as_completed(jobs):
            lang=jobs[job]
            try: result=job.result(); results.append(result); print(f"PASS {lang}: {count} oracle cases",flush=True)
            except Exception as e: failures.append((lang,str(e))); print(f"FAIL {lang}: {e}",file=sys.stderr,flush=True)
    report={"algorithm":ALGORITHM,"verified_at":dt.datetime.now(dt.timezone.utc).isoformat(),"platform":platform.platform(),"results":results,"failures":failures}
    (root/"verification.json").write_text(json.dumps(report,indent=2)+"\n")
    return int(bool(failures))

if __name__ == "__main__": raise SystemExit(main())
