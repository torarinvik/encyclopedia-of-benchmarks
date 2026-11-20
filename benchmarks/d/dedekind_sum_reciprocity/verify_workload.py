"""Static workload and ten-port inventory for Dedekind reciprocity."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "dedekind_sum_reciprocity"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "unit-modulus": 29_999_700_001,
    "zero-sum-modulus-two": 29_999_700_001,
    "positive-dedekind-sum": 29_999_700_003,
    "zero-sum-coprime-pair": 29_999_700_001,
    "negative-dedekind-sum": 29_999_699_995,
    "three-euclidean-levels": 29_999_699_999,
    "negative-large-shape": 29_999_699_985,
    "maximum-positive-sum": 39_999_400_003,
    "maximum-negative-sum": 19_999_999_999,
    "non-coprime": -1,
    "zero-numerator-nonunit-modulus": -1,
    "noncanonical-numerator": -1,
    "zero-modulus": -1,
    "modulus-over-bound": -1,
    "trailing-value": -1,
    "short-frame": -1,
    "null-input": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 2
    assert workload["input"]["maximum_parseable_length"] == 3
    assert workload["output"]["valid_result_range"] == [1, 59_999_400_001]
    assert workload["output"]["maximum_result"] == 59_999_400_001
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    assert set(cases) == set(EXPECTED)
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    assert cases["unit-modulus"]["input_values"] == [0, 1]
    assert cases["positive-dedekind-sum"]["input_values"] == [1, 3]
    assert cases["maximum-positive-sum"]["input_values"] == [1, 100000]
    assert cases["maximum-negative-sum"]["input_values"] == [99999, 100000]
    for oracle_name in ("primary_oracle.py", "independent_oracle.py"):
        assert (PACKAGE / oracle_name).is_file()
    primary = (PACKAGE / "primary_oracle.py").read_text(encoding="utf-8")
    assert "MAX_VALID_INPUT_LENGTH = 2" in primary
    assert "MAX_PARSEABLE_INPUT_LENGTH = 3" in primary
    assert "def expected_result(" in primary
    independent = (PACKAGE / "independent_oracle.py").read_text(encoding="utf-8")
    assert "def verify_candidate(" in independent
    assert "product_numerator_sum" in independent
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/d/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "d" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
