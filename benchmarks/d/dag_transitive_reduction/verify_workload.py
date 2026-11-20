"""Static fixture, documentation-link, and source-presence reviewer."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "dag_transitive_reduction"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "isolated-vertices": 0,
    "one-edge": 1,
    "three-vertex-chain": 2,
    "transitive-triangle": 2,
    "diamond-cover": 4,
    "chain-with-shortcuts": 3,
    "non-topological-vertex-labels": 2,
    "disjoint-components": 3,
    "maximum-complete-order-dag": 7,
    "directed-cycle": -1,
    "self-loop": -1,
    "duplicate-arc": -1,
    "endpoint-out-of-range": -1,
    "truncated-frame": -1,
    "one-trailing-word": -1,
    "maximum-parseable-trailing-word": -1,
    "vertex-count-out-of-range": -1,
    "edge-count-out-of-range": -1,
    "null-input": -1,
    "null-input-at-parseable-bound": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["exact_length"] == "2 + 2*M"
    assert workload["input"]["maximum_valid_length"] == 58
    assert workload["input"]["maximum_parseable_length"] == 59
    assert workload["output"]["maximum_result"] == 28
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    assert set(cases) == set(EXPECTED)
    for case in cases.values():
        if case.get("input_is_null", False):
            assert case["input_values"] == [] and case["expected_result"] == -1
        else:
            assert case["input_length"] == len(case["input_values"])
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    maximum = cases["maximum-complete-order-dag"]
    assert len(maximum["input_values"]) == 58
    assert maximum["input_values"][:2] == [8, 28]
    pairs = list(zip(maximum["input_values"][2::2], maximum["input_values"][3::2]))
    assert pairs == [(u, v) for u in range(8) for v in range(u + 1, 8)]
    trailing = cases["maximum-parseable-trailing-word"]
    assert len(trailing["input_values"]) == 59
    assert trailing["input_values"][:-1] == maximum["input_values"]
    assert cases["null-input-at-parseable-bound"]["input_length"] == 59
    assert (PACKAGE / "primary_oracle.py").is_file()
    assert "def expected_result(" in (PACKAGE / "primary_oracle.py").read_text(encoding="utf-8")
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    independent_text = independent.read_text(encoding="utf-8")
    assert "for removed_edge, (source, target) in enumerate(arcs)" in independent_text
    assert "queue.popleft()" in independent_text
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in (
        "../../t/transitive_closure_reflexive_matrix/README.md",
        "../../t/topological_sort/README.md", "RIGHTS.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    ):
        assert (PACKAGE / relative).is_file(), f"missing README target: {relative}"
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/d/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "d" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"


if __name__ == "__main__":
    verify()
