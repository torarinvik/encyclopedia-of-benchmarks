# Static inventory

This package contains ten language ports, a bounded linked-node-pool primary
reference, a nested-list independent reference, workload fixtures,
provenance/rights, and static inventory metadata. Input is bounded to 161 i64
words with a 162-word parser boundary; output is at most 640 bytes and
workspace is capped at 2,048 bytes. Workload fixtures pin left-on-tie
placement, a right choice when its chain is shorter, duplicate insertion,
lookup/deletion, inconsistent supplied hashes, malformed framing, the
40-operation 640-byte output, and full-table insertion failure.

`verify_workload.py` exposes `workload_issues() -> list[str]` to compare every
fixture with both references. `check_inventory.py` exposes
`static_issues() -> list[str]`. The package is registered in the
`i64_array_bytes_output` runner and verifier. Neither checker was run during
drafting.
