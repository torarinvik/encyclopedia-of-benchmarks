#!/usr/bin/env python3
"""Check existing distance-formula ABI builds against an independent oracle."""
from __future__ import annotations

import argparse
import hashlib
from itertools import product
import json
import math
from pathlib import Path
import random
import subprocess

from distance_formula_oracle import COORDINATE_BOUND, expected_result

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "distance_formula"
WORKLOAD = ROOT / "benchmarks/d/distance_formula/workload.json"


def corpus(workload: dict) -> list[tuple[int, ...]]:
    cases = {tuple(case["input_values"]) for case in workload["cases"]}
    palette = (-COORDINATE_BOUND, -1, 0, 1, COORDINATE_BOUND)
    cases.update(product(palette, repeat=4))
    generator = random.Random(0xD157F04)
    for _ in range(256):
        cases.add(tuple(generator.randint(-COORDINATE_BOUND, COORDINATE_BOUND)
                        for _ in range(4)))
    for length in range(8):
        cases.add(tuple(range(length)))
    for index in range(4):
        for invalid in (-2**63, -COORDINATE_BOUND - 1,
                        COORDINATE_BOUND + 1, 2**63 - 1):
            values = [0, 0, 0, 0]
            values[index] = invalid
            cases.add(tuple(values))
    return sorted(cases)


def batch(workload: dict) -> tuple[str, int]:
    absolute = workload["output"]["absolute_tolerance"]
    relative = workload["output"]["relative_tolerance"]
    for case in workload["cases"]:
        actual = expected_result(case["input_values"])
        expected = case["expected_result"]
        if (not math.isfinite(expected)
                or abs(actual - expected) > absolute + relative * abs(expected)):
            raise ValueError("workload disagrees with oracle: " + case["id"])
    cases = corpus(workload)
    lines = [str(len(cases))]
    for values in cases:
        lines.append(" ".join(map(str, (len(values), 0, expected_result(values),
                                       relative, absolute, *values))))
    return "\n".join(lines) + "\n", len(cases)


def verify(manifest_path: Path, data: str, count: int) -> dict:
    manifest = json.loads(manifest_path.read_text())
    if (manifest.get("algorithm") != ALGORITHM
            or manifest.get("family") != "i64_array_float64"
            or manifest.get("function_symbol") != ALGORITHM):
        raise ValueError("unexpected ABI build: " + str(manifest_path))
    checker = manifest["binaries"]["i64_array_float64_check"]
    path = Path(checker["path"])
    if hashlib.sha256(path.read_bytes()).hexdigest() != checker["sha256"]:
        raise ValueError("checker differs from its build receipt: " + str(path))
    completed = subprocess.run([str(path)], input=data, capture_output=True,
                               text=True, timeout=28)
    if completed.returncode:
        raise RuntimeError(str(path) + ": " + completed.stderr)
    observed = json.loads(completed.stdout)
    if observed.get("cases_checked") != count:
        raise ValueError("incomplete corpus: " + str(path))
    return {"manifest": str(manifest_path), "cases_checked": count,
            "checker_sha256": checker["sha256"]}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-manifest", type=Path, action="append", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    workload = json.loads(WORKLOAD.read_text())
    data, count = batch(workload)
    result = {"algorithm": ALGORITHM,
              "corpus_sha256": hashlib.sha256(data.encode()).hexdigest(),
              "results": [verify(path, data, count) for path in args.build_manifest]}
    text = json.dumps(result, indent=2)
    if args.output:
        args.output.write_text(text + "\n")
    print(text)


if __name__ == "__main__":
    main()
