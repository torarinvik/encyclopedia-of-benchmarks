"""Static fixture and port inventory checks; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "max_min_triangle_height_triangulation"
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
    "triangle-rational-altitude": 73897,
    "square-equal-triangulation-heights": 4105,
    "pentagon-edge-insertion-improves-fan": 65681,
    "maximum-valid-frame": 65681,
    "maximum-parseable-trailing-value": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 11
    assert workload["input"]["maximum_parseable_length"] == 12
    assert workload["output"]["maximum_result"] == 134480384

    cases = {case["id"]: case for case in workload["cases"]}
    for case_id, expected in EXPECTED.items():
        case = cases[case_id]
        assert case["expected_result"] == expected
        assert case["input_length"] == len(case["input_values"])
    assert len(cases["maximum-valid-frame"]["input_values"]) == 11
    assert len(cases["maximum-parseable-trailing-value"]["input_values"]) == 12
    assert cases["maximum-parseable-trailing-value"]["input_values"][:-1] == cases["maximum-valid-frame"]["input_values"]

    for oracle in ("primary_oracle.py", "independent_oracle.py"):
        assert (PACKAGE / oracle).is_file()

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/m/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "m" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing exported symbol in {language} port"
        assert f"]({relative})" in readme, f"missing or incorrect README link for {language}"
    assert (PACKAGE / "RIGHTS.md").is_file()
    assert "[`workload.json`](workload.json)" in readme


if __name__ == "__main__":
    verify()
