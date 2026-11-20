# Package inventory

- Algorithm: `hash_heap_priority_queue_trace`
- ABI: `i64_array_bytes_output`
- Input: `[U,B,q,(opcode,operand)*q]`, 131 valid / 132 parseable words.
- Output: one i64 result per operation plus a count header; maximum 520 bytes.
- Workspace: 4,096 bytes.
- Complexity: primary `O(q(B + log(q+1)))`, state `O(Bq+q)`; independent
  scan `O(q^2)`, state `O(q)`.
- Primary reference: per-bucket binary min-heaps.
- Independent reference: direct scan of the live item list.
- Workload: `workload.json`, with both signed-word and literal LE-byte outputs;
  reconciled by the package-local static workload helper.
- Source boundary: NIST DADS hash-heap and linear-hash descriptions; the
  function, arena, mapping formula, tie rule, and operation protocol are
  clean-room profile choices.
- Shared `i64_array_bytes_output` runner and verifier, catalog, root README,
  and expansion-coverage registration are integrated. All ten ports were
  reviewed statically; no programs, helpers, checks, compilers, or benchmarks
  were run.

## Native sources

| Language | Path |
| --- | --- |
| C | `c/h/hash_heap_priority_queue_trace.c` |
| C3 | `c3/h/hash_heap_priority_queue_trace.c3` |
| C++ | `cpp/h/hash_heap_priority_queue_trace.cpp` |
| Elisa | `elisa/h/hash_heap_priority_queue_trace.elisa` |
| Mojo | `mojo/h/hash_heap_priority_queue_trace.mojo` |
| Nim | `nim/h/hash_heap_priority_queue_trace.nim` |
| Odin | `odin/h/hash_heap_priority_queue_trace.odin` |
| Rust | `rust/h/hash_heap_priority_queue_trace.rs` |
| V | `v/h/hash_heap_priority_queue_trace.v` |
| Zig | `zig/h/hash_heap_priority_queue_trace.zig` |
