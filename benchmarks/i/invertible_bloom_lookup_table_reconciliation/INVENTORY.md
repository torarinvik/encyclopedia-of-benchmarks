# Static inventory

This package contains ten ports, a cell-mutating primary oracle, an
independent residual-term rebuild oracle, and a bounded workload. The profile
accepts at most 18 i64 input words, allows a 19-word parser boundary, emits at
most 152 bytes, and caps workspace at 2,048 bytes. The workload includes a
complete two-sided difference, identical-set cancellation, a fixed-hash
incomplete 2-core, malformed sets, and the maximum-output capacity boundary.

`verify_workload.py` exposes `workload_issues() -> list[str]` to compare all
fixtures against both references. `check_inventory.py` exposes
`static_issues() -> list[str]`. Neither was run while drafting. Shared suite
and catalog registration are integrated.
