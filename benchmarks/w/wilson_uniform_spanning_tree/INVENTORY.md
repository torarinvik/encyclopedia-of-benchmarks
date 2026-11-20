# Static inventory

This package has ten language ports, Wilson's successor-pointer reference, an
independent buffered-walk/last-occurrence loop-erasure reference, and a bounded
caller-supplied draw tape workload. The contract allows at most 8 vertices,
64 draws per walk, 448 total draws, 508 words in a structurally valid frame,
509 words at the parser boundary, 112 output bytes, and 2,048 workspace bytes.

`verify_workload.py` exposes `workload_issues() -> list[str]` to compare every
pinned fixture against both references. `check_inventory.py` exposes
`static_issues() -> list[str]`. Neither was run while drafting. Suite and
catalog registration remain root-owned.
