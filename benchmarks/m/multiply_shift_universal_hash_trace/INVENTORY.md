# Static inventory

The package contains ten language ports, one widened-product primary
reference, one add-and-double independent reference, and a bounded workload.
The workload pins 66 valid input words, a 67-word trailing-data parse bound,
256 maximum output bytes, and 128 bytes of algorithm workspace.

`verify_workload.py` exposes `workload_issues() -> list[str]` for the shared
suite to compare each fixture against both references; its standalone entry
point is retained. Neither that API nor `check_inventory.py` was run while
this package was drafted.

The shared byte-output runner, verifier, and catalog integration remain with
the root agent.
