"""Static workload and ten-port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
SYMBOL = "tree_center_rerooting_dp"
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
    assert workload["input"]["maximum_valid_length"] == 127
    assert workload["input"]["maximum_parseable_length"] == 127
    assert workload["output"]["maximum_bytes"] == 16
    assert workload["workspace"]["bytes"] == 16
    assert workload["measurement"]["comparison_model"] == "i64_array_bytes_output_call"
    assert workload["contract"]["algorithm"].startswith("Root the tree")
    for case in workload["cases"]:
        assert case["input_length"] == len(case["input_values"])
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (directory, extension) in PORTS.items():
        source = REPOSITORY / directory / "t" / f"{SYMBOL}.{extension}"
        relative = f"../../../{directory}/t/{SYMBOL}.{extension}"
        assert source.is_file(), f"missing {language} port: {source}"
        assert SYMBOL in source.read_text(encoding="utf-8"), f"missing {language} symbol"
        assert f"]({relative})" in readme, f"missing {language} link"
    assert (PACKAGE / "primary_oracle.py").is_file()
    assert (PACKAGE / "independent_oracle.py").is_file()
    assert (PACKAGE / "RIGHTS.md").is_file()


if __name__ == "__main__":
    verify()
