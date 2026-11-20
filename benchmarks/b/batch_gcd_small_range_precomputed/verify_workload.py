"""Static workload and ten-port inventory checks; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as direct_expected
from .primary_oracle import expected_output as primary_expected

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "batch_gcd_small_range_precomputed"
PORTS = {
    "C": ("c", "c"), "C3": ("c3", "c3"), "C++": ("cpp", "cpp"),
    "Elisa": ("elisa", "elisa"), "Mojo": ("mojo", "mojo"),
    "Nim": ("nim", "nim"), "Odin": ("odin", "odin"),
    "Rust": ("rust", "rs"), "V": ("v", "v"), "Zig": ("zig", "zig"),
}


def verify() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    assert workload["algorithm"] == SYMBOL
    assert workload["function_symbol"] == SYMBOL
    assert workload["abi"] == "i64_array_bytes_output"
    assert workload["input"]["maximum_valid_length"] == 130
    assert workload["input"]["maximum_parseable_length"] == 131
    assert workload["output"]["maximum_bytes"] == 512
    assert workload["workspace"]["bytes"] == 4096
    assert workload["measurement"]["comparison_model"] == "i64_array_bytes_output_call"
    for case in workload["cases"]:
        assert case["input_length"] == len(case["input_values"])
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        actual = primary_expected(case["input_values"], **kwargs)
        assert actual == direct_expected(case["input_values"], **kwargs)
        assert actual[0] == case["expected_result"]
        assert actual[1].hex() == case["expected_output_hex"]
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        source = REPOSITORY / directory / "b" / f"{SYMBOL}.{extension}"
        relative = f"../../../{directory}/b/{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"missing {language} link"
    for name in ("RIGHTS.md", "INVENTORY.md", "primary_oracle.py", "independent_oracle.py"):
        assert (PACKAGE / name).is_file(), f"missing package artifact: {name}"


if __name__ == "__main__":
    verify()
