"""Static fixture and port inventory checks for linear_extension_count."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "linear_extension_count"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "empty-poset": 1,
    "four-element-antichain": 24,
    "five-element-chain": 1,
    "two-minima-one-maximum": 2,
    "diamond-poset": 2,
    "two-disjoint-two-chains": 6,
    "chain-and-isolated-vertex": 4,
    "three-vertex-cycle": 0,
    "self-loop": 0,
    "maximum-valid-antichain": 479001600,
    "maximum-parseable-trailing-value": -1,
    "n-out-of-range": -1,
    "mask-bit-out-of-range": -1,
    "truncated-mask-list": -1,
    "null-input": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 13
    assert workload["input"]["maximum_parseable_length"] == 14
    assert workload["output"]["maximum_result"] == 479001600
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    maximum = cases["maximum-valid-antichain"]
    assert len(maximum["input_values"]) == 13
    assert maximum["input_values"][0] == 12
    assert maximum["expected_result"] == 479001600
    trailing = cases["maximum-parseable-trailing-value"]
    assert len(trailing["input_values"]) == 14
    assert trailing["input_values"][:-1] == maximum["input_values"]
    assert (PACKAGE / "primary_oracle.py").is_file()
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    assert "def verify_candidate(" in independent.read_text(encoding="utf-8")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/l/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "l" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
