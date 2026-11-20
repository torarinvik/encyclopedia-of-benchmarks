# Package inventory

- Algorithm: `combinations_with_repetition_lexicographic`
- ABI: `i64_array_bytes_output`
- Primary reference: `primary_oracle.py` (rightmost-coordinate lexicographic successor)
- Independent reference: `independent_oracle.py` (recursive nondecreasing tuple generation)
- Workload: `workload.json` (empty set/length cases, repetitions, small hand-pinned enumerations, maximum output, malformed framing, and output errors)
- Workload reconciliation helper: `verify_workload.py` (authored only; not run)
- Static path and metadata inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared suite status: registered in the `i64_array_bytes_output` runner and verifier.

The native workspace cap is 128 bytes. The primary requires only four current tuple bytes and bounded scalar/index state; it writes to caller-owned output only after validating the exact output size and capacity. The maximum output is 142 bytes, containing a u16 count and 35 four-byte tuples. No package helper, native port, compiler, or test has been executed.

## Native source paths

| Language | Source |
| --- | --- |
| C | `c/c/combinations_with_repetition_lexicographic.c` |
| C3 | `c3/c/combinations_with_repetition_lexicographic.c3` |
| C++ | `cpp/c/combinations_with_repetition_lexicographic.cpp` |
| Elisa | `elisa/c/combinations_with_repetition_lexicographic.elisa` |
| Mojo | `mojo/c/combinations_with_repetition_lexicographic.mojo` |
| Nim | `nim/c/combinations_with_repetition_lexicographic.nim` |
| Odin | `odin/c/combinations_with_repetition_lexicographic.odin` |
| Rust | `rust/c/combinations_with_repetition_lexicographic.rs` |
| V | `v/c/combinations_with_repetition_lexicographic.v` |
| Zig | `zig/c/combinations_with_repetition_lexicographic.zig` |
