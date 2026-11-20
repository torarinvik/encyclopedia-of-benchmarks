"""Static path and workload inventory for multiset combinations."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]


def verify_static_inventory() -> None:
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    assert inventory["algorithm"] == "combinations_with_repetition_lexicographic"
    assert inventory["abi"] == "i64_array_bytes_output"
    assert inventory["suite_status"] == "registered_i64_array_bytes_output"
    ports = inventory["native_ports"]
    assert set(ports) == {"C", "C3", "C++", "Elisa", "Mojo", "Nim", "Odin", "Rust", "V", "Zig"}
    for relative_path in ports.values():
        assert (ROOT / relative_path).is_file(), relative_path
    for key in ("primary_oracle", "independent_oracle", "workload", "rights",
                "inventory_doc", "static_inventory_helper", "workload_reference_helper"):
        assert (ROOT / inventory[key]).is_file(), inventory[key]
    assert workload["algorithm"] == inventory["algorithm"]
    assert workload["abi"] == inventory["abi"]
    assert workload["source"]["discovery_index_revision"] == "1d475861d7141ef2fafff293d9339f56e4b0f5db"
    assert workload["input"]["maximum_valid_length"] == 2
    assert workload["input"]["maximum_parseable_length"] == 3
    assert workload["output"]["maximum_bytes"] == 142
    assert workload["workspace"]["bytes"] == 128
    assert workload["contract"]["n_range"] == [0, 4]
    assert workload["contract"]["r_range"] == [0, 4]
    assert workload["contract"]["maximum_tuple_count"] == 35
    assert len(workload["cases"]) >= 10
