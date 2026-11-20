"""Static package inventory, documentation, and oracle review for TST."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/t/ternary_search_trie.c",
    "c3": "c3/t/ternary_search_trie.c3",
    "cpp": "cpp/t/ternary_search_trie.cpp",
    "elisa": "elisa/t/ternary_search_trie.elisa",
    "mojo": "mojo/t/ternary_search_trie.mojo",
    "nim": "nim/t/ternary_search_trie.nim",
    "odin": "odin/t/ternary_search_trie.odin",
    "rust": "rust/t/ternary_search_trie.rs",
    "v": "v/t/ternary_search_trie.v",
    "zig": "zig/t/ternary_search_trie.zig",
}
EXPORTED_MARKERS = {
    "c": ("int64_t ternary_search_trie(",),
    "c3": ('@export("ternary_search_trie")', "fn long ternary_search_trie("),
    "cpp": ('extern "C" std::int64_t ternary_search_trie(',),
    "elisa": ("export fn ternary_search_trie(",),
    "mojo": ('@export("ternary_search_trie")', "fn ternary_search_trie("),
    "nim": ('exportc: "ternary_search_trie"', "proc ternary_search_trie*("),
    "odin": ('ternary_search_trie :: proc "c"',),
    "rust": ('pub unsafe extern "C" fn ternary_search_trie(',),
    "v": ("@[export: 'ternary_search_trie']", "pub fn ternary_search_trie("),
    "zig": ("export fn ternary_search_trie(",),
}
PARSEABLE_LIMIT_MARKERS = {
    "c": "MAX_PARSEABLE_INPUT_VALUES = 578",
    "c3": "MAX_PARSEABLE_INPUT_VALUES = 578",
    "cpp": "MAX_PARSEABLE_INPUT_VALUES = 578",
    "elisa": "TST_MAX_PARSEABLE_INPUT_VALUES: usize = 578",
    "mojo": "MAX_PARSEABLE_INPUT_VALUES = 578",
    "nim": "MaxParseableInputValues = 578",
    "odin": "MAX_PARSEABLE_INPUT_VALUES :: c.size_t(578)",
    "rust": "MAX_PARSEABLE_INPUT_VALUES: usize = 578",
    "v": "max_parseable_input_values = 578",
    "zig": "MAX_PARSEABLE_INPUT_VALUES: usize = 578",
}


def validate_inventory(workload: dict) -> None:
    """Validate package files and workload fixtures without subprocesses."""
    sys.path.insert(0, str(PACKAGE))
    from independent_oracle import expected_result as independent_expected
    from primary_oracle import expected_result as primary_expected

    expected_files = {
        "README.md",
        "RIGHTS.md",
        "primary_oracle.py",
        "independent_oracle.py",
        "workload.json",
        "verify_workload.py",
    }
    missing = sorted(name for name in expected_files if not (PACKAGE / name).is_file())
    if missing:
        raise ValueError(f"missing package files: {missing}")
    missing_ports = sorted(path for path in PORTS.values() if not (ROOT / path).is_file())
    if missing_ports:
        raise ValueError(f"missing language ports: {missing_ports}")
    readme = (PACKAGE / "README.md").read_text()
    for language, relative_path in PORTS.items():
        link = f"](../../../{relative_path})"
        if link not in readme:
            raise ValueError(f"missing README source link for {language}")
        source = (ROOT / relative_path).read_text()
        if any(marker not in source for marker in EXPORTED_MARKERS[language]):
            raise ValueError(f"missing exported symbol marker for {language}")
        if PARSEABLE_LIMIT_MARKERS[language] not in source:
            raise ValueError(f"missing 578-value parseable limit for {language}")
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        local_target = target.split("#", 1)[0]
        if local_target and not (PACKAGE / local_target).resolve().is_file():
            raise ValueError(f"unresolved local README link: {target}")
    if workload.get("algorithm") != "ternary_search_trie" or workload.get("abi") != "i64_array_scalar":
        raise ValueError("workload identity or ABI mismatch")
    if workload.get("function_symbol") != "ternary_search_trie":
        raise ValueError("workload function symbol mismatch")
    if workload.get("input", {}).get("record_width") != 9:
        raise ValueError("unexpected record width")
    if workload.get("input", {}).get("maximum_valid_input_length") != 577:
        raise ValueError("maximum valid input length is not documented")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 578:
        raise ValueError("maximum parseable input length is not documented")
    measurement = workload.get("measurement", {})
    if measurement.get("comparison_model") != "i64_array_scalar_call":
        raise ValueError("missing scalar-call measurement model")
    cases = workload.get("cases", [])
    if len(cases) < 8 or len({case.get("id") for case in cases}) != len(cases):
        raise ValueError("fixture inventory is incomplete or has duplicate ids")
    for case in cases:
        values = case.get("input_values")
        if not isinstance(values, list) or len(values) > 578:
            if not (case.get("input_is_null") and values == [] and case.get("input_length") == 0):
                raise ValueError(f"invalid fixture frame: {case.get('id')}")
        if case.get("input_length") != len(values):
            raise ValueError(f"fixture length mismatch: {case.get('id')}")
        if not isinstance(case.get("expected_result"), int):
            raise ValueError(f"invalid expected scalar: {case.get('id')}")
        expected = case["expected_result"]
        if primary_expected(values, case.get("input_is_null", False), case.get("input_length")) != expected:
            raise ValueError(f"primary oracle mismatch: {case.get('id')}")
        if independent_expected(values, case.get("input_is_null", False), case.get("input_length")) != expected:
            raise ValueError(f"independent oracle mismatch: {case.get('id')}")
    if not any(case.get("input_length") == 577 for case in cases):
        raise ValueError("maximum valid frame is absent")
    if not any(case.get("input_length") == 578 for case in cases):
        raise ValueError("maximum parseable malformed frame is absent")
    trailing = next((case for case in cases if case.get("id") == "trailing_value"), None)
    if trailing is None or trailing.get("input_values") != [0, 99] or trailing.get("expected_result") != -1:
        raise ValueError("small trailing-value rejection fixture is absent")
    maximum_parseable = next(
        (case for case in cases if case.get("id") == "maximum_parseable_frame_with_trailing_value"),
        None,
    )
    if (
        maximum_parseable is None
        or maximum_parseable.get("input_length") != 578
        or len(maximum_parseable.get("input_values", [])) != 578
        or maximum_parseable.get("expected_result") != -1
    ):
        raise ValueError("578-value trailing-frame rejection fixture is absent")


def review() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text())
    validate_inventory(workload)


if __name__ == "__main__":
    review()
