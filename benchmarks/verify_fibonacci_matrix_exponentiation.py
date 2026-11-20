"""Unexecuted ABI verifier for modular matrix Fibonacci."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys

from build_abi import EXTENSIONS, OPTIONAL_EXTENSIONS, ROOT, build
from fibonacci_modular_oracle import expected_result
from run_float64_pair import encode_case

ALGORITHM = "fibonacci_matrix_exponentiation"


def corpus():
    workload = json.loads((ROOT / "benchmarks/f/fibonacci_matrix_exponentiation/workload.json")
                          .read_text(encoding="utf-8"))
    tolerance = float(workload["measurement"]["input_scaled_tolerance"])
    pairs = {(float(n), float(m)) for n in range(1, 101)
             for m in (1, 2, 3, 7, 97, 65537, 4294967295)}
    for case in workload["cases"]:
        first, second, expected = encode_case(case, tolerance, ALGORITHM)
        if expected != expected_result(first, second):
            raise ValueError(f"workload reference disagreement: {case['id']}")
        pairs.add((first, second))
    pairs.update((n, m) for n in (0.0, -1.0, 1.5, 9007199254740991.0,
                                  9007199254740992.0)
                 for m in (0.0, 1.0, 97.0, 4294967295.0, 4294967296.0))
    pairs.update(((5.0, 2.5), (float("nan"), 1.0), (1.0, float("inf"))))
    rows = [(a, b, expected_result(a, b)) for a, b in pairs]
    return str(len(rows)) + "\n" + "".join(
        f"{a:.17g} {b:.17g} {expected:.17g} {tolerance:.17g}\n" for a, b, expected in rows
    ), len(rows), workload


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices={**EXTENSIONS, **OPTIONAL_EXTENSIONS},
                        default=list(EXTENSIONS))
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/float64_pair/fibonacci_matrix_exponentiation")
    parser.add_argument("--elisa-compiler")
    args = parser.parse_args()
    data, count, workload = corpus()
    for language in args.languages:
        directory = args.build_dir / language
        compiler = args.elisa_compiler if language == "elisa" else None
        manifest = build(ALGORITHM, language, directory, compiler=compiler,
                         with_checker=True, family="float64_pair")
        checker = manifest["binaries"]["float64_pair_check"]["path"]
        checked = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=120)
        if checked.returncode or json.loads(checked.stdout)["cases_checked"] != count:
            raise RuntimeError(f"{language} float64 pair check failed: {checked.stderr}")
        records_path = directory / "verification-records.jsonl"
        records_path.unlink(missing_ok=True)
        recorded = subprocess.run(
            [sys.executable, str(ROOT / "benchmarks/run_float64_pair.py"),
             "--build-manifest", str(directory / "build.json"),
             "--samples", "1", "--warmups", "0", "--repetitions", "1",
             "--output", str(records_path)],
            cwd=ROOT, capture_output=True, text=True, timeout=120)
        if recorded.returncode:
            raise RuntimeError(f"{language} recorder failed: {recorded.stderr}")
        records = [json.loads(line) for line in records_path.read_text(encoding="utf-8").splitlines()]
        if len(records) != len(workload["cases"]):
            raise RuntimeError(f"{language} recorder omitted workload cases")
        for case, record in zip(workload["cases"], records):
            if (record["algorithm"] != ALGORITHM
                    or record["implementation"]["language"] != language
                    or record["workload"]["expected_result"] != case["expected_result"]
                    or record["measurement"]["observed_result"] != case["expected_result"]):
                raise RuntimeError(f"{language} recorder mismatch: {case['id']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
