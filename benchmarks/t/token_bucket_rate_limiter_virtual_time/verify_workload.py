"""Static workload and ten-language inventory; never imports benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "token_bucket_rate_limiter_virtual_time"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}
EXPECTED = {
    "empty-trace": 0,
    "capacity-without-refill": 7,
    "refill-after-empty": 43,
    "refill-saturates-at-capacity": 11,
    "zero-capacity": 0,
    "maximum-elapsed-ticks": 3,
    "maximum-request-count-and-result-mask": 9223372036854775807,
    "capacity-out-of-range": -1,
    "negative-refill-rate": -1,
    "request-count-above-bound": -1,
    "negative-elapsed-ticks": -1,
    "elapsed-ticks-above-bound": -1,
    "trailing-input": -1,
    "truncated-header": -1,
    "null-input": -1,
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["abi"] == "i64_array_scalar"
    assert workload["function_symbol"] == SYMBOL
    assert workload["input"]["maximum_valid_length"] == 66
    assert workload["input"]["maximum_parseable_length"] == 66
    assert workload["output"]["maximum_result"] == (1 << 63) - 1
    cases = {case["id"]: case for case in workload["cases"]}
    assert len(cases) == len(workload["cases"])
    for case in cases.values():
        assert case["input_length"] == len(case["input_values"])
        values = case["input_values"]
        expected = case["expected_result"]
        is_null = case.get("input_is_null", False)
        assert primary(values, is_null, case["input_length"]) == expected
        assert independent(values, is_null, case["input_length"]) == expected
    for case_id, expected in EXPECTED.items():
        assert cases[case_id]["expected_result"] == expected
    maximum = cases["maximum-request-count-and-result-mask"]
    assert len(maximum["input_values"]) == 66
    assert maximum["input_values"][2] == 63
    assert (PACKAGE / "primary_oracle.py").is_file()
    independent = PACKAGE / "independent_oracle.py"
    assert independent.is_file()
    assert "def verify_candidate(" in independent.read_text(encoding="utf-8")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        relative = f"../../../{directory}/t/{SYMBOL}.{extension}"
        source = REPOSITORY / directory / "t" / f"{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"incorrect {language} README path"
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
