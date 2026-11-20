"""Static workload and ten-port inventory for polynomial Hensel lifting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "hensel_lifting_polynomial_root"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "linear-three-digit-lift": 42,
    "quadratic-three-digit-lift": 108,
    "large-prime-power-and-root": 999,
    "prime-two-lift": 1,
    "exponent-one-no-lift": 3,
    "maximum-degree-frame": 0,
    "maximum-parseable-trailing-value": -1,
    "nonsimple-seed": -1,
    "seed-is-not-a-root": -1,
    "composite-base-not-prime": -1,
    "prime-power-over-cap": -1,
    "coefficient-out-of-range": -1,
    "truncated-coefficients": -1,
    "null-input": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 9
    assert workload["input"]["maximum_parseable_length"] == 10
    assert workload["output"]["maximum_result"] == 83_520
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    maximum = cases["maximum-degree-frame"]
    assert len(maximum["input_values"]) == 9
    assert maximum["input_values"][0] == 4
    assert maximum["input_values"][1:3] == [17, 4]
    trailing = cases["maximum-parseable-trailing-value"]
    assert len(trailing["input_values"]) == 10
    assert trailing["input_values"][:-1] == maximum["input_values"]
    for oracle_name in ("primary_oracle.py", "independent_oracle.py"):
        assert (PACKAGE / oracle_name).is_file()
    independent = (PACKAGE / "independent_oracle.py").read_text(encoding="utf-8")
    assert "def verify_candidate(" in independent
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/h/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "h" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
