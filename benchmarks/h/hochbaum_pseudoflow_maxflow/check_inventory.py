"""Static package, fixture, and ten-port inventory for Hochbaum pseudoflow."""

from __future__ import annotations

import json
import importlib.util
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]


def _load_oracle(name: str, filename: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        f"_hochbaum_pseudoflow_{name}", PACKAGE / filename,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load package oracle: {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_PRIMARY = _load_oracle("primary", "primary_oracle.py")
_CUT = _load_oracle("cut", "independent_oracle.py")
MAX_ITERATIONS = _PRIMARY.MAX_ITERATIONS
MAX_PARSEABLE_INPUT_LENGTH = _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
MAX_RESULT = _PRIMARY.MAX_RESULT
MAX_VALID_INPUT_LENGTH = _PRIMARY.MAX_VALID_INPUT_LENGTH
SYMBOL = _PRIMARY.SYMBOL
primary_oracle = _PRIMARY.expected_result
cut_oracle = _CUT.expected_result
PORTS = {
    "C": ("c", "c"),
    "C3": ("c3", "c3"),
    "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"),
    "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"),
    "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"),
    "V": ("v", "v"),
    "Zig": ("zig", "zig"),
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["algorithm"] == SYMBOL
    assert workload["function_symbol"] == SYMBOL
    assert workload["abi"] == "i64_array_scalar"
    assert workload["input"]["layout"] == "[N,M,source,sink,(u,v,capacity)*M]"
    assert workload["input"]["maximum_valid_length"] == MAX_VALID_INPUT_LENGTH == 76
    assert workload["input"]["maximum_parseable_length"] == MAX_PARSEABLE_INPUT_LENGTH == 77
    assert workload["output"]["maximum_result"] == MAX_RESULT == 2400
    policy = workload["algorithm_policy"]
    assert policy["maximum_outer_iterations"] == MAX_ITERATIONS == 512
    assert "highest-label" in policy["variant"]
    assert "FIFO" in policy["equal_label_tie"]
    assert "labeled l-1" in policy["merger"]
    assert "strong" in policy["merger"]
    assert "full excess" in policy["normalization"]

    cases = workload["cases"]
    by_id = {case["id"]: case for case in cases}
    assert len(by_id) == len(cases)
    for case in cases:
        values = case["input_values"]
        assert case["input_length"] == len(values)
        expected = case["expected_result"]
        assert primary_oracle(values, case.get("input_is_null", False), case["input_length"]) == expected
        assert cut_oracle(values, case.get("input_is_null", False), case["input_length"]) == expected

    maximum = by_id["maximum-parallel-direct-frame"]
    assert maximum["input_length"] == MAX_VALID_INPUT_LENGTH
    assert maximum["expected_result"] == MAX_RESULT
    trailing = by_id["maximum-parseable-trailing-value"]
    assert trailing["input_length"] == MAX_PARSEABLE_INPUT_LENGTH
    assert trailing["input_values"][:-1] == maximum["input_values"]
    assert trailing["expected_result"] == -1

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        source = REPOSITORY / directory / "h" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} export"
        assert f"](../../../{directory}/h/{SYMBOL}.{extension})" in readme, f"bad {language} README link"

    assert (PACKAGE / "RIGHTS.md").is_file()
    assert (PACKAGE / "primary_oracle.py").is_file()
    assert (PACKAGE / "independent_oracle.py").is_file()


if __name__ == "__main__":
    verify()
