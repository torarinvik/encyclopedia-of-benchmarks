"""Static fixture metadata and language-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "tree_center"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "singleton": (8, "0000000000000000"),
    "two-vertex-tree": (16, "00000000000000000100000000000000"),
    "odd-diameter-path": (8, "0200000000000000"),
    "even-diameter-path": (16, "02000000000000000300000000000000"),
    "star": (8, "0000000000000000"),
    "asymmetric-branching-tree": (8, "0300000000000000"),
    "maximum-path": (16, "1f000000000000002000000000000000"),
    "cycle-with-isolated-vertex": (-1, ""),
    "repeated-edge": (-1, ""), "self-loop": (-1, ""),
    "endpoint-out-of-range": (-1, ""), "truncated-tree": (-1, ""),
    "trailing-input": (-1, ""), "short-output-capacity": (-2, ""),
    "null-output": (-2, ""), "null-input": (-1, ""),
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_bytes_output"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 127
    assert workload["input"]["maximum_parseable_length"] == 127
    assert workload["output"]["maximum_bytes"] == 16
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"]) == len(EXPECTED)
    for case_id, (result, payload) in EXPECTED.items():
        case = cases[case_id]
        assert case["input_length"] == len(case["input_values"])
        assert case["expected_result"] == result
        assert case["expected_output_hex"] == payload
    maximum = cases["maximum-path"]
    assert len(maximum["input_values"]) == 127
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/t/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "t" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "primary_oracle.py").is_file()
    assert (PACKAGE / "independent_oracle.py").is_file()
    assert (PACKAGE / "RIGHTS.md").is_file()
    assert (REPOSITORY / "benchmarks" / "tree_center_oracle.py").is_file()


if __name__ == "__main__":
    verify()
