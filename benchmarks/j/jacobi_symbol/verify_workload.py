"""Static workload and ten-port inventory for Jacobi symbol evaluation."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "jacobi_symbol"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "supplementary-law-two-prime": 2,
    "prime-nonresidue": 0,
    "reciprocity-sign-flip": 0,
    "reciprocity-reversed-pair": 2,
    "composite-positive-symbol-not-residue": 2,
    "composite-square-denominator": 2,
    "stanford-reciprocity-example": 0,
    "second-prime-nonresidue": 0,
    "noncoprime-numerator": 1,
    "zero-numerator": 1,
    "unit-denominator": 2,
    "maximum-odd-denominator": 1,
    "trailing-word": -1,
    "negative-numerator": -1,
    "noncanonical-numerator": -1,
    "even-denominator": -1,
    "denominator-too-large": -1,
    "null-input": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 2
    assert workload["input"]["maximum_parseable_length"] == 3
    assert workload["output"]["valid_result_range"] == [0, 2]
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    assert cases["unit-denominator"]["input_values"] == [0, 1]
    assert cases["composite-positive-symbol-not-residue"]["input_values"] == [2, 15]
    assert cases["maximum-odd-denominator"]["input_values"] == [0, 999999999]
    assert (PACKAGE / "primary_oracle.py").is_file()
    independent_path = PACKAGE / "independent_oracle.py"
    assert independent_path.is_file()
    independent = independent_path.read_text(encoding="utf-8")
    assert "def verify_candidate(" in independent
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/j/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "j" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
