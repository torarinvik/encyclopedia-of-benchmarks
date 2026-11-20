# Static package inventory

The package implements `buddy_system_allocator` with the
`i64_array_bytes_output` ABI in ten source files listed in `INVENTORY.json`.
The trace is bounded to 64 operations and a 256-unit arena; the output limit
is 5,640 bytes and the documented workspace cap is 16,384 bytes.

Package artifacts are the README, rights note, workload, primary order-indexed
free-list reference, independent sorted-dyadic-interval reference,
`verify_workload.py`, and `check_inventory.py`. The workload verifier compares
both references with each pinned result/output and checks exact-capacity,
one-byte-short, null-output, and malformed-input precedence behavior. The
workload covers the empty arena, request rounding and splitting, full
recursive coalescing, exhaustion, malformed framing, invalid stateful frees,
null pointers, and insufficient capacity.

The inventory checker and workload verifier are included for later review and
have not been run. No language port, test, script, build, compiler, profiler,
or benchmark was executed during this draft.
