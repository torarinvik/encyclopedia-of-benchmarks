#!/usr/bin/env python3
"""Compile and check false-position ports against the exact roots of x^2 - x."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_float64_pair import encode_case

ALGORITHM = "false_position"
TOLERANCE = 1e-10


def target_root(a: float, b: float) -> float | None:
    valid_a = 0.125 <= a <= 0.875
    valid_b = (-2.0 <= b <= -0.125) or (1.125 <= b <= 3.0)
    if not valid_a or not valid_b or not (a * a - a < 0.0 and b * b - b > 0.0):
        return None
    return 0.0 if b < 0.0 else 1.0


def corpus(workload: dict) -> tuple[str, int]:
    pairs: set[tuple[float, float, float]] = set()
    for case in workload["cases"]:
        a, b, expected = encode_case(case, TOLERANCE, ALGORITHM)
        root = target_root(a, b)
        if root is None:
            if expected != -1.0:
                raise ValueError(f"invalid workload case has a non-sentinel result: {case['id']}")
        elif expected != root:
            raise ValueError(f"workload case does not name its isolated root: {case['id']}")
        pairs.add((a, b, expected))

    first_values = [index / 64.0 for index in range(8, 57)]
    second_values = [-2.0, -1.5, -1.0, -0.5, -0.125, 1.125, 1.5, 2.0, 3.0]
    for a in first_values:
        for b in second_values:
            root = target_root(a, b)
            assert root is not None
            pairs.add((a, b, root))

    rng = random.Random(20261015)
    for _ in range(512):
        a = rng.uniform(0.125, 0.875)
        b = rng.uniform(-2.0, -0.125) if rng.randrange(2) == 0 else rng.uniform(1.125, 3.0)
        root = target_root(a, b)
        assert root is not None
        pairs.add((a, b, root))

    invalid_pairs = [
        (-0.5, 2.0), (0.1, -1.0), (0.9, 2.0), (0.5, 0.0),
        (0.5, 0.75), (0.5, 1.0), (0.5, 0.999), (0.5, 3.5),
        (0.875, -2.1), (0.124, 1.5), (0.125, -0.124), (0.876, 2.0),
    ]
    pairs.update((a, b, -1.0) for a, b in invalid_pairs)
    lines = [f"{len(pairs)}\n"]
    lines.extend(" ".join(format(value, ".17g") for value in (a, b, expected, TOLERANCE)) + "\n"
                 for a, b, expected in sorted(pairs))
    return "".join(lines), len(pairs)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_pair")
    checker = manifest["binaries"]["float64_pair_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"false-position C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete root corpus")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_pair/false_position")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and language selections must be unique")
    workload = json.loads((ROOT / "benchmarks/f/false_position/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "false_position-corpus.txt"
    corpus_path.write_text(data, encoding="utf-8")
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        jobs = {executor.submit(verify, language, directory / language, args.elisa_compiler,
                                data, case_count): language for language in args.languages}
        for job in as_completed(jobs):
            language = jobs[job]
            try:
                result = job.result()
            except Exception as error:
                print(f"FAIL {ALGORITHM}/{language}: {error}", file=sys.stderr, flush=True)
                return 1
            results.append(result)
            print(f"PASS {ALGORITHM}/{language}: {case_count} root cases", flush=True)
    report = {"algorithm": ALGORITHM, "verified_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "platform": platform.platform(), "corpus_sha256": sha256_file(corpus_path),
              "all_passed": len(results) == len(args.languages),
              "results": sorted(results, key=lambda item: item["language"])}
    report_path = directory / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"verification report: {report_path}")
    return 0 if report["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
