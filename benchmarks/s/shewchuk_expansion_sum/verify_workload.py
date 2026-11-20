"""Static fixture and language-port inventory; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "shewchuk_expansion_sum"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "empty-expansion": 288230376151711745,
    "single-half-unit": 288230378836066305,
    "large-cancellation-recovers-quarter-ulp": 288230376151711746,
    "cancellation-then-fractional-term": 288230376957018114,
    "signed-small-units": 288230376151711743,
    "three-overlapping-exponents": 288230376151711752,
    "maximum-valid-cancellation": 288230376151711751,
    "valid-minus-one-unit-not-invalid": 288230376151711744,
    "maximum-parseable-trailing-value": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 33
    assert workload["input"]["maximum_parseable_length"] == 34
    assert workload["output"]["result_range"] == [1, 576460752303423489]
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    maximum = cases["maximum-valid-cancellation"]
    assert len(maximum["input_values"]) == 33
    trailing = cases["maximum-parseable-trailing-value"]
    assert len(trailing["input_values"]) == 34
    assert trailing["input_values"][:-1] == maximum["input_values"]
    assert (PACKAGE / "primary_oracle.py").is_file()
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    assert "def verify_candidate(" in independent.read_text(encoding="utf-8")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/s/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "s" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
