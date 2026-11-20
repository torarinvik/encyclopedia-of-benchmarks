"""Static workload, reference, link, and ten-port inventory."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "free_polyomino_enumeration"
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


def _load(name: str, filename: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        f"_free_polyomino_{name}", PACKAGE / filename,
    )
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load package reference: {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_PRIMARY = _load("primary", "primary_oracle.py")
_INDEPENDENT = _load("independent", "independent_oracle.py")


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["algorithm"] == SYMBOL
    assert workload["function_symbol"] == SYMBOL
    assert workload["abi"] == "i64_array_scalar"
    assert workload["input"]["layout"] == "[n]"
    assert workload["input"]["maximum_n"] == _PRIMARY.MAX_N == 8
    assert workload["input"]["maximum_valid_length"] == _PRIMARY.MAX_VALID_INPUT_LENGTH == 1
    assert workload["input"]["maximum_parseable_length"] == _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH == 2
    assert workload["output"]["maximum_result"] == _PRIMARY.MAX_RESULT == 369
    assert workload["algorithm_policy"]["shape_state_capacity"] == _PRIMARY.MAX_SHAPES == 512

    cases = workload["cases"]
    by_id = {case["id"]: case for case in cases}
    assert len(by_id) == len(cases)
    for case in cases:
        values = case["input_values"]
        assert case["input_length"] == len(values)
        expected = case["expected_result"]
        null = case.get("input_is_null", False)
        assert _PRIMARY.expected_result(values, null, case["input_length"]) == expected
        assert _INDEPENDENT.expected_result(values, null, case["input_length"]) == expected

    ids = ("monomino", "domino", "triomino", "tetromino", "pentomino", "hexomino", "heptomino", "octomino-maximum")
    for index, expected in enumerate(_PRIMARY.FREE_COUNTS):
        assert by_id[ids[index]]["expected_result"] == expected
    trailing = by_id["maximum-parseable-trailing-value"]
    assert trailing["input_length"] == _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
    assert trailing["input_values"] == [8, 99]
    assert trailing["expected_result"] == -1

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        source = REPOSITORY / directory / "f" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} export"
        assert f"](../../../{directory}/f/{SYMBOL}.{extension})" in readme, f"bad {language} README link"
    for filename in ("RIGHTS.md", "primary_oracle.py", "independent_oracle.py"):
        assert (PACKAGE / filename).is_file(), f"missing package file: {filename}"


if __name__ == "__main__":
    verify()
