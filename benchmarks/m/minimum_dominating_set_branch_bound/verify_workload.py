"""Static fixture, documentation-link, and port-presence reviewer."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "minimum_dominating_set_branch_bound"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "single-vertex": 1,
    "edgeless-five-vertex-graph": 5,
    "complete-five-vertex-graph": 1,
    "five-vertex-path": 2,
    "five-cycle": 2,
    "star-center-dominates": 1,
    "disjoint-edge-and-three-vertex-path": 2,
    "greedy-trap-requires-search": 2,
    "twelve-cycle": 4,
    "maximum-complete-frame": 1,
    "self-loop": -1,
    "duplicate-edge": -1,
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
    assert workload["input"]["maximum_valid_length"] == 134
    assert workload["input"]["maximum_parseable_length"] == 135
    assert workload["output"]["maximum_result"] == 12
    assert workload["input"]["vertex_count_range"] == [1, 12]
    assert workload["input"]["edge_count_range"] == [0, 66]
    assert workload["input"]["graph"].endswith("either endpoint order is accepted")
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
    maximum = cases["maximum-complete-frame"]
    assert len(maximum["input_values"]) == 134
    assert maximum["input_values"][:2] == [12, 66]
    pairs = list(zip(maximum["input_values"][2::2], maximum["input_values"][3::2]))
    assert pairs == [(u, v) for u in range(12) for v in range(u + 1, 12)]
    trailing = cases["maximum-parseable-trailing-word"]
    assert len(trailing["input_values"]) == 135
    assert trailing["input_values"][:-1] == maximum["input_values"]
    assert cases["null-input-at-parseable-bound"]["input_length"] == 135
    assert (PACKAGE / "primary_oracle.py").is_file()
    primary_text = (PACKAGE / "primary_oracle.py").read_text(encoding="utf-8")
    assert "def expected_result(" in primary_text
    for literal in ("MAX_VERTICES = 12", "MAX_EDGES = 66", "MAX_VALID_INPUT_LENGTH = 134",
                    "MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1"):
        assert literal in primary_text
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    independent_text = independent.read_text(encoding="utf-8")
    assert "for chosen in combinations(range(n), size)" in independent_text
    assert "covered |= closed[vertex]" in independent_text
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for relative in (
        "../../w/weighted_connected_dominating_set/README.md",
        "../../t/tree_weighted_dominating_set/README.md",
        "../../m/minimal_dominating_sets_interval/README.md",
        "RIGHTS.md", "workload.json", "primary_oracle.py",
        "independent_oracle.py", "verify_workload.py",
    ):
        assert (PACKAGE / relative).is_file(), f"missing README target: {relative}"
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/m/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "m" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"


if __name__ == "__main__":
    verify()
