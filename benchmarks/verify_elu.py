#!/usr/bin/env python3
"""Verify ELU ports through the two-input binary64 ABI."""

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
from elu_oracle import (
    ALPHA_MAX,
    ALPHA_MIN,
    INVALID_RESULT,
    X_MAX,
    X_MIN,
    expected_result as elu_oracle,
)
from run_float64_pair import encode_case, matches

ALGORITHM = "elu"


def corpus(workload: dict) -> tuple[str, int]:
    relative = float(workload["measurement"]["relative_tolerance"])
    absolute = float(workload["measurement"].get("absolute_tolerance", 0.0))
    if workload.get("algorithm") != ALGORITHM:
        raise ValueError("ELU workload must name the elu algorithm")
    input_spec = workload["input"]
    if (input_spec.get("x_minimum") != X_MIN or input_spec.get("x_maximum") != X_MAX
            or input_spec.get("alpha_minimum") != ALPHA_MIN
            or input_spec.get("alpha_maximum") != ALPHA_MAX
            or input_spec.get("invalid_input_result") != INVALID_RESULT):
        raise ValueError("ELU workload bounds/sentinel disagree with the pinned oracle")

    pairs: dict[tuple[float, float], float] = {}

    def add(first: float, second: float, expected: float | None = None) -> None:
        if expected is None:
            expected = elu_oracle(first, second)
        encoded = encode_case({
            "input_values": [first, second],
            "expected_result": expected,
        }, relative, ALGORITHM, absolute)
        x, alpha, workload_expected = encoded
        exact = elu_oracle(x, alpha)
        if not matches(workload_expected, exact, relative, x, alpha, absolute):
            raise ValueError(f"ELU expected value disagrees with pinned oracle at ({x}, {alpha})")
        pairs[(x, alpha)] = exact

    for case in workload["cases"]:
        x, alpha, expected = encode_case(case, relative, ALGORITHM, absolute)
        exact = elu_oracle(x, alpha)
        if not matches(expected, exact, relative, x, alpha, absolute):
            raise ValueError(f"workload disagrees with independent ELU oracle: {case['id']}")
        pairs[(x, alpha)] = exact

    # Cover both branches, signed/ordinary zero, and each inclusive numeric limit.
    for x in (X_MIN, -99.999, -1e-15, -0.0, 0.0, 1e-15, 99.999, X_MAX):
        for alpha in (ALPHA_MIN, -1.0, 0.0, 1.0, ALPHA_MAX):
            add(x, alpha)

    # Finite values just outside each domain edge must produce the invalid sentinel.
    for x, alpha in (
        (X_MIN - 1e-9, 1.0), (X_MAX + 1e-9, 1.0),
        (-1.0, ALPHA_MIN - 1.0), (-1.0, ALPHA_MAX + 1.0),
    ):
        add(x, alpha)

    rng = random.Random(20261016)
    for _ in range(256):
        add(rng.uniform(X_MIN, X_MAX), rng.uniform(ALPHA_MIN, ALPHA_MAX))

    lines = [f"{len(pairs)}\n"]
    for (x, alpha), expected in sorted(pairs.items()):
        tolerance = max(relative, absolute / max(1.0, abs(x), abs(alpha)))
        lines.append(" ".join(format(value, ".17g") for value in
                              (x, alpha, expected, tolerance)) + "\n")
    return "".join(lines), len(pairs)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           data: str, case_count: int) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="float64_pair")
    checker = manifest["binaries"]["float64_pair_check"]["path"]
    checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"ELU C ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the complete ELU oracle corpus")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--jobs", type=int, default=3)
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_pair/elu")
    args = parser.parse_args()
    if args.jobs < 1 or len(set(args.languages)) != len(args.languages):
        parser.error("jobs must be positive and selected languages must be unique")
    workload = json.loads((ROOT / "benchmarks/e/elu/workload.json").read_text(encoding="utf-8"))
    data, case_count = corpus(workload)
    directory = args.build_dir.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    corpus_path = directory / "elu-corpus.txt"
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
            print(f"PASS {ALGORITHM}/{language}: {case_count} oracle pairs", flush=True)
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
