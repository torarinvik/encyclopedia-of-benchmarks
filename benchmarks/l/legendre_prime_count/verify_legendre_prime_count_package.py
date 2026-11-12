"""Static package inventory and fixture/oracle consistency checker.

Do not execute this checker under the repository's source-only work policy.
"""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "legendre_prime_count"

PORTS = (
    "c/l/legendre_prime_count.c",
    "c3/l/legendre_prime_count.c3",
    "cpp/l/legendre_prime_count.cpp",
    "elisa/l/legendre_prime_count.elisa",
    "mojo/l/legendre_prime_count.mojo",
    "nim/l/legendre_prime_count.nim",
    "odin/l/legendre_prime_count.odin",
    "rust/l/legendre_prime_count.rs",
    "v/l/legendre_prime_count.v",
    "zig/l/legendre_prime_count.zig",
)


def _load_oracle(path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_package() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload algorithm and function symbol must match package symbol")
    if workload.get("abi") != "i64_scalar":
        errors.append("workload ABI must be i64_scalar")
    contract = workload.get("contract", {})
    if contract.get("input_range") != [0, 10000] or contract.get("invalid_input_result") != -1:
        errors.append("workload input range or invalid-input result differs from the package contract")
    for relative_path in PORTS:
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing port: {relative_path}")
            continue
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            errors.append(f"cannot read {relative_path}: {error}")
            continue
        if SYMBOL not in source:
            errors.append(f"export symbol is absent from {relative_path}")
    for required in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")
    try:
        primary = _load_oracle(ROOT / "benchmarks/legendre_prime_count_oracle.py", "legendre_primary")
        independent = _load_oracle(
            ROOT / "benchmarks/legendre_prime_count_independent_oracle.py", "legendre_independent"
        )
    except (OSError, ValueError) as error:
        return errors + [f"cannot load package oracles: {error}"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        errors.append("workload cases must be a nonempty list")
        return errors
    for case in cases:
        name = case.get("id", "<unnamed>")
        value = case.get("input_value")
        expected = case.get("expected_result")
        for label, oracle in (("primary", primary), ("independent", independent)):
            if oracle.expected_output(value) != expected:
                errors.append(f"{name}: {label} oracle disagrees with expected result")
    return errors


if __name__ == "__main__":
    problems = validate_package()
    if problems:
        raise SystemExit("\n".join(problems))
    print("legendre_prime_count package inventory and fixtures are consistent")
