"""Static workload and language-port inventory for Barrett reduction."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "barrett_reduction"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "empty-batch": 0,
    "mixed-small-remainders": 44,
    "zero-and-exact-multiple": 42,
    "reciprocal-estimate-needs-correction": 32641,
    "maximum-valid-frame": 5111730,
    "maximum-parseable-trailing-value": -1,
    "modulus-too-small": -1,
    "count-too-large": -1,
    "operand-equals-modulus-square": -1,
    "negative-operand": -1,
    "truncated-batch": -1,
    "null-input": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 14
    assert workload["input"]["maximum_parseable_length"] == 15
    assert workload["output"]["maximum_result"] == 5111730
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    maximum = cases["maximum-valid-frame"]
    assert len(maximum["input_values"]) == 14
    assert maximum["input_values"][1] == 12
    assert maximum["expected_result"] == 5111730
    trailing = cases["maximum-parseable-trailing-value"]
    assert len(trailing["input_values"]) == 15
    assert trailing["input_values"][:-1] == maximum["input_values"]
    assert (PACKAGE / "primary_oracle.py").is_file()
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    assert "def verify_candidate(" in independent.read_text(encoding="utf-8")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/b/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "b" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
