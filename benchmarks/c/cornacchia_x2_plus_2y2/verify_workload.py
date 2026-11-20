"""Static workload and ten-port inventory for Cornacchia's x^2+2y^2 form."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "cornacchia_x2_plus_2y2"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "smallest-valid-prime": 1025,
    "no-descent-at-boundary": 3073,
    "one-euclidean-step": 3074,
    "unit-x-coordinate": 1027,
    "two-euclidean-steps": 3076,
    "small-x-and-large-y": 1030,
    "wrong-root-nonresidue-case": -1,
    "composite-with-root": -1,
    "noncanonical-opposite-root": -1,
    "zero-root": -1,
    "prime-over-bound": -1,
    "even-modulus": -1,
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
    assert workload["output"]["maximum_result"] == 1_023_683
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    assert cases["smallest-valid-prime"]["input_values"] == [3, 1]
    assert cases["one-euclidean-step"]["input_values"] == [17, 7]
    assert cases["two-euclidean-steps"]["input_values"] == [41, 11]
    assert cases["composite-with-root"]["input_values"] == [9, 4]
    assert cases["trailing-value"]["input_values"] == [17, 7, 0]
    for oracle_name in ("primary_oracle.py", "independent_oracle.py"):
        assert (PACKAGE / oracle_name).is_file()
    independent = (PACKAGE / "independent_oracle.py").read_text(encoding="utf-8")
    assert "def verify_candidate(" in independent
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/c/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "c" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
