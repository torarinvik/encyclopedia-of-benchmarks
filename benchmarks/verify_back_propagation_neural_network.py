#!/usr/bin/env python3
"""Verify scalar DenseLayer updates across the nine portable language ports."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import json
import math
from pathlib import Path
import platform
import random
import subprocess
import sys

from back_propagation_oracle import back_propagation_step
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_bytes_output import fnv1a

ALGORITHM = "back_propagation_neural_network"
WORKLOAD_PATH = ROOT / "benchmarks/b/back_propagation_neural_network/workload.json"
SCALE = 1_000_000.0


def loss_for(values: list[int]) -> float:
    x, target, hidden_weight, hidden_bias, output_weight, output_bias = (
        value / SCALE for value in values[:6]
    )
    hidden = 1.0 / (1.0 + math.exp(-(hidden_weight * x - hidden_bias)))
    prediction = 1.0 / (1.0 + math.exp(-(output_weight * hidden - output_bias)))
    return (target - prediction) ** 2


def check_finite_difference(values: list[int], output: bytes) -> None:
    if values[6] < 50_000:
        return
    observed = [int.from_bytes(output[index:index + 8], "little", signed=True) / SCALE
                for index in range(0, 56, 8)]
    learning_rate = values[6] / SCALE
    step = 0.00001
    for parameter_index, result_index in ((2, 3), (3, 4), (4, 5), (5, 6)):
        plus = values.copy()
        minus = values.copy()
        plus[parameter_index] += 10
        minus[parameter_index] -= 10
        numeric_gradient = (loss_for(plus) - loss_for(minus)) / (2.0 * step)
        initial = values[parameter_index] / SCALE
        updated = observed[result_index]
        recovered_gradient = (initial - updated) / learning_rate
        if not math.isclose(recovered_gradient, numeric_gradient, rel_tol=2e-4, abs_tol=2e-5):
            raise ValueError(f"finite-difference update mismatch for parameter {parameter_index}")
    source_loss = loss_for(values)
    if not math.isclose(observed[0], source_loss, rel_tol=0, abs_tol=1.1e-6):
        raise ValueError("quantized workload loss differs from the forward equation")


def corpus(workload: dict) -> tuple[str, int, dict[tuple[int, ...], tuple[int, bytes]]]:
    cases: dict[tuple[int, ...], tuple[int, bytes]] = {}

    def include(values: tuple[int, ...], declared: tuple[int, str] | None = None) -> None:
        result, output = back_propagation_step(list(values))
        if declared is not None and (result != declared[0] or output.hex() != declared[1]):
            raise ValueError("published workload differs from the scalar-update oracle")
        cases[values] = result, output

    for case in workload["cases"]:
        include(tuple(case["input_values"]),
                (case["expected_result"], case["expected_output_hex"]))

    rng = random.Random(20261015)
    for _ in range(512):
        values = (rng.randrange(-1_000_000, 1_000_001),
                  rng.randrange(-1_000_000, 1_000_001),
                  rng.randrange(-2_000_000, 2_000_001),
                  rng.randrange(-2_000_000, 2_000_001),
                  rng.randrange(-2_000_000, 2_000_001),
                  rng.randrange(-2_000_000, 2_000_001),
                  rng.randrange(50_000, 300_001))
        include(values)

    for invalid in ((), (0,), (0, 0, 0, 0, 0, 0), (1, 2, 3, 4, 5, 6, 7, 8),
                    (1_000_001, 0, 0, 0, 0, 0, 1),
                    (0, 0, 2_000_001, 0, 0, 0, 1),
                    (0, 0, 0, 0, 0, 0, -1),
                    (0, 0, 0, 0, 0, 0, 300_001)):
        include(invalid)

    records = sorted(cases.items())
    for values, (result, output) in records:
        if result == 56:
            check_finite_difference(list(values), output)
    # A valid update with zero output capacity must fail without modifying output.
    records.append(((500_000, 700_000, 200_000, -100_000, 400_000, 100_000, 100_000), (-2, b"")))
    lines = [f"{len(records)}\n"]
    for values, (result, output) in records:
        values_text = "" if not values else " " + " ".join(map(str, values))
        lines.append(f"{len(values)} {result} {len(output)}{values_text} {output.hex() if output else '-'}\n")
    return "".join(lines), len(records), dict(cases)


def verify(language: str, directory: Path, elisa_compiler: str | None,
           checker_input: str, case_count: int, cases: dict[tuple[int, ...], tuple[int, bytes]],
           workload: dict) -> dict:
    manifest = build(ALGORITHM, language, directory,
                     compiler=elisa_compiler if language == "elisa" else None,
                     with_checker=True, family="i64_array_bytes_output")
    checker = manifest["binaries"]["i64_array_bytes_output_check"]["path"]
    checked = subprocess.run([checker], input=checker_input, capture_output=True,
                             text=True, timeout=120)
    if checked.returncode:
        raise RuntimeError(f"byte-output ABI check failed: {checked.stderr}")
    if json.loads(checked.stdout)["cases_checked"] != case_count:
        raise RuntimeError("checker did not consume the full gradient/update corpus")

    output_path = directory / "verification-records.jsonl"
    output_path.unlink(missing_ok=True)
    recorded = subprocess.run(
        [sys.executable, str(ROOT / "benchmarks/run_i64_array_bytes_output.py"),
         "--build-manifest", str(directory / "build.json"), "--samples", "1",
         "--warmups", "0", "--repetitions", "1", "--output", str(output_path)],
        cwd=ROOT, capture_output=True, text=True, timeout=120)
    if recorded.returncode:
        raise RuntimeError(f"workload recorder failed: {recorded.stdout}\n{recorded.stderr}")
    records = [json.loads(line) for line in output_path.read_text(encoding="utf-8").splitlines()]
    if len(records) != len(workload["cases"]):
        raise RuntimeError("recorder emitted an unexpected number of workload records")
    for case, record in zip(workload["cases"], records):
        values = tuple(case["input_values"])
        expected_result, expected_bytes = cases[values]
        if (record["algorithm"] != ALGORITHM
                or record["implementation"]["language"] != language
                or record["implementation"]["source_sha256"] != manifest["source_sha256"]
                or record["workload"]["input_values"] != list(values)
                or record["workload"]["expected_result"] != expected_result
                or record["measurement"]["observed_result"] != expected_result
                or record["measurement"]["result_checksum"] != fnv1a(expected_bytes)):
            raise RuntimeError(f"recorded result/provenance mismatch: {case['id']}")
    return {"algorithm": ALGORITHM, "language": language, "status": "passed",
            "oracle_cases": case_count, "source_sha256": manifest["source_sha256"],
            "workload_records": len(records), "build_manifest": str(directory / "build.json"),
            "build_manifest_sha256": sha256_file(directory / "build.json"),
            "recorder_output": str(output_path), "recorder_output_sha256": sha256_file(output_path)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", nargs="+", choices=EXTENSIONS, default=list(EXTENSIONS))
    parser.add_argument("--elisa-compiler")
    parser.add_argument("--build-dir", type=Path, default=ROOT / "build/i64_array_bytes_output/back_propagation_neural_network")
    parser.add_argument("--jobs", type=int, default=1)
    args = parser.parse_args()
    if not 1 <= args.jobs <= len(args.languages):
        parser.error("jobs must be between 1 and the selected language count")
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    checker_input, case_count, cases = corpus(workload)
    args.build_dir.mkdir(parents=True, exist_ok=True)
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        futures = {
            executor.submit(verify, language, args.build_dir / language,
                            args.elisa_compiler, checker_input, case_count, cases, workload): language
            for language in args.languages
        }
        for future in as_completed(futures): results.append(future.result())
    results.sort(key=lambda record: record["language"])
    report = {"schema_version": 1, "algorithm": ALGORITHM, "status": "passed",
              "verified_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
              "platform": {"system": platform.system(), "release": platform.release(),
                           "machine": platform.machine(), "python": platform.python_version()},
              "oracle_cases_per_language": case_count,
              "workload_records_per_language": len(workload["cases"]), "languages": results}
    report_path = args.build_dir / "verification.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "oracle_cases_per_language": case_count,
                      "languages": [record["language"] for record in results],
                      "report": str(report_path)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
