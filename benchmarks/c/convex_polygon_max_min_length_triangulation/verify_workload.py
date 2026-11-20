"""Static fixture and port inventory checks; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "convex_polygon_max_min_length_triangulation"
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
EXPECTED = {
    "triangle-shortest-side-empty-mask": 4608,
    "square-cut-right-angle": 8193,
    "pentagon-keeps-acute-corner": 4620,
    "maximum-valid-hexagon-tied-hull-minima": 8199,
    "maximum-parseable-trailing-value": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 13
    assert workload["input"]["maximum_parseable_length"] == 14
    assert workload["contract"]["maximum_greedy_steps"] == 24
    assert workload["output"]["maximum_result"] == 262655

    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        case = cases[case_id]
        assert case["expected_result"] == expected
    assert len(cases["triangle-shortest-side-empty-mask"]["input_values"]) == 7
    assert cases["triangle-shortest-side-empty-mask"]["expected_result"] % 512 == 0
    assert len(cases["maximum-valid-hexagon-tied-hull-minima"]["input_values"]) == 13
    trailing = cases["maximum-parseable-trailing-value"]
    assert len(trailing["input_values"]) == 14
    assert trailing["input_values"][:-1] == cases["maximum-valid-hexagon-tied-hull-minima"]["input_values"]

    assert (PACKAGE / "primary_oracle.py").is_file()
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    assert "def verify_candidate(" in independent.read_text(encoding="utf-8")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/c/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "c" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing exported symbol in {language} port"
        assert f"]({relative})" in readme, f"missing or incorrect README link for {language}"
    assert (PACKAGE / "RIGHTS.md").is_file()
    assert "[`workload.json`](workload.json)" in readme


if __name__ == "__main__":
    verify()
