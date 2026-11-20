# Static inventory

This package contains ten language ports, a flat-array mutating primary
reference, an immutable-bucket rebuilding reference, workload fixtures,
provenance/rights notes, and static metadata. Input is bounded to 97 valid
i64 words with a 98-word parser boundary; output is at most 256 bytes and
workspace is capped at 1,024 bytes. The workload covers lookup misses,
fingerprint multiplicity and deletion, a successful cuckoo relocation,
kick-cap failure, malformed records, and maximum-output capacity handling.

`verify_workload.py` exports `workload_issues() -> list[str]` to compare pinned
fixtures with both references. `check_inventory.py` exports
`static_issues() -> list[str]`. The shared `i64_array_bytes_output` runner and
verifier register this package. Neither helper was executed.
