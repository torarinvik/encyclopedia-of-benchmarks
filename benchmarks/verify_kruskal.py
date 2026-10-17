#!/usr/bin/env python3
"""Check Kruskal ports against an independent dense Prim minimum-spanning-tree oracle."""
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

ALGORITHM = "kruskal"
MAX_VERTICES, MAX_EDGES, MAX_WEIGHT = 64, 4096, 2**31 - 1

def oracle(values: list[int]) -> int:
    if not values or len(values) < 2 or len(values) > 2 + 3 * MAX_EDGES or any(type(x) is not int for x in values): return -2
    vertices, edge_count = values[0], values[1]
    if not 0 <= vertices <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES: return -2
    if len(values) != 2 + 3 * edge_count or (vertices == 0 and edge_count != 0): return -2
    if vertices == 0: return 0
    present = [[False] * vertices for _ in range(vertices)]
    weights = [[0] * vertices for _ in range(vertices)]
    for index in range(edge_count):
        u, v, weight = values[2 + 3 * index:5 + 3 * index]
        if not (0 <= u < vertices and 0 <= v < vertices and 0 <= weight <= MAX_WEIGHT): return -2
        if u != v and (not present[u][v] or weight < weights[u][v]):
            present[u][v] = present[v][u] = True
            weights[u][v] = weights[v][u] = weight
    in_tree = [False] * vertices
    has_best = [False] * vertices
    best = [0] * vertices
    has_best[0] = True
    total = 0
    for _ in range(vertices):
        eligible = [v for v in range(vertices) if not in_tree[v] and has_best[v]]
        if not eligible: return -1
        chosen = min(eligible, key=lambda v: (best[v], v))
        in_tree[chosen] = True
        total += best[chosen]
        for v in range(vertices):
            if not in_tree[v] and present[chosen][v] and (not has_best[v] or weights[chosen][v] < best[v]):
                has_best[v] = True
                best[v] = weights[chosen][v]
    return total

def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    def include(values: list[int] | tuple[int, ...]) -> None:
        packed = tuple(values)
        cases[packed] = oracle(list(packed))
    for vertices in range(5):
        pairs = [(u, v) for u in range(vertices) for v in range(u + 1, vertices)]
        for states in product((-1, 0, 5), repeat=len(pairs)):
            edges = [(u, v, weight) for (u, v), weight in zip(pairs, states) if weight >= 0]
            include([vertices, len(edges), *(item for edge in edges for item in edge)])
    rng = random.Random(20261014)
    for _ in range(768):
        vertices = rng.randrange(MAX_VERTICES + 1)
        edges = []
        if vertices:
            for u in range(vertices):
                for v in range(u + 1, vertices):
                    if rng.random() < 0.08: edges.append((u, v, rng.randrange(MAX_WEIGHT + 1)))
        include([vertices, len(edges), *(item for edge in edges for item in edge)])
    for values in [[], [0], [0, 1, 0, 0, 1], [-1, 0], [65, 0], [2, -1], [2, 1], [2, 0, 0],
                   [2, 1, 0, 2, 1], [2, 1, -1, 0, 1], [2, 1, 0, 1, -1],
                   [2, 1, 0, 1, MAX_WEIGHT + 1], [1, 1, 0, 0, 0], [0, 1]]:
        include(values)
    for case in workload["cases"]:
        values = encode_case(case, algorithm=ALGORITHM)
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
    if json.loads(checked.stdout)["cases_checked"] != case_count: raise RuntimeError("incomplete corpus")
    output = directory / "verification-records.jsonl"; output.unlink(missing_ok=True)
    recorded = subprocess.run([sys.executable, str(ROOT / "benchmarks/run_i64_array_scalar.py"),
        "--build-manifest", str(directory / "build.json"), "--samples", "1", "--warmups", "0",
        "--repetitions", "1", "--output", str(output)], cwd=ROOT, capture_output=True, text=True, timeout=180)
    if recorded.returncode: raise RuntimeError(f"workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]): raise RuntimeError("unexpected workload record count")
    for case, record in zip(workload["cases"], records):
        values = encode_case(case, algorithm=ALGORITHM); expected = oracle(values)
        if (record["algorithm"] != ALGORITHM or record["implementation"]["language"] != language
            or record["implementation"]["source_sha256"] != manifest["source_sha256"]
            or record["workload"]["input_length"] != len(values) or record["workload"]["input_values"] != values
            or record["workload"]["expected_result"] != expected or record["measurement"]["observed_result"] != expected):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed", "oracle_cases": case_count,
        "source_sha256": manifest["source_sha256"], "workload_records": len(records),
        "workload_sha256": sha256_file(ROOT / "benchmarks/k/kruskal/workload.json"),
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
    workload_path = ROOT / "benchmarks/k/kruskal/workload.json"
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = (args.build_dir or ROOT / "build/i64_array_scalar/k/kruskal").resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "kruskal-corpus.txt"; corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, lang, directory / lang, args.elisa_compiler, data, case_count, workload): lang for lang in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try: result = job.result()
            except Exception as error:
                result = {"algorithm": ALGORITHM, "language": language, "status": "failed", "error": str(error)}
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
            else: print(f"PASS {ALGORITHM}/{language}: {case_count} graph cases, {result['workload_records']} workload records", flush=True)
            results.append(result)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "platform": platform.platform(), "all_passed": len(results) == len(args.languages) and all(r["status"] == "passed" for r in results),
        "corpus_sha256": sha256_file(corpus_path), "verification_source_sha256": sha256_file(Path(__file__)),
        "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"; report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1
if __name__ == "__main__": raise SystemExit(main())
