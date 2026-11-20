# Static package inventory

The exported ABI is `zobrist_position_hash_trace(input, length, output,
capacity)`, with the bounded frame in [`README.md`](README.md) and
[`workload.json`](workload.json). The package-local references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py); the latter recomputes every
position hash from all slots. [`verify_workload.py`](verify_workload.py) and
[`check_inventory.py`](check_inventory.py) are static validation entry points
and have not been run.

| Language | Source |
| --- | --- |
| C | [`c/z/zobrist_position_hash_trace.c`](../../../c/z/zobrist_position_hash_trace.c) |
| C3 | [`c3/z/zobrist_position_hash_trace.c3`](../../../c3/z/zobrist_position_hash_trace.c3) |
| C++ | [`cpp/z/zobrist_position_hash_trace.cpp`](../../../cpp/z/zobrist_position_hash_trace.cpp) |
| Elisa | [`elisa/z/zobrist_position_hash_trace.elisa`](../../../elisa/z/zobrist_position_hash_trace.elisa) |
| Mojo | [`mojo/z/zobrist_position_hash_trace.mojo`](../../../mojo/z/zobrist_position_hash_trace.mojo) |
| Nim | [`nim/z/zobrist_position_hash_trace.nim`](../../../nim/z/zobrist_position_hash_trace.nim) |
| Odin | [`odin/z/zobrist_position_hash_trace.odin`](../../../odin/z/zobrist_position_hash_trace.odin) |
| Rust | [`rust/z/zobrist_position_hash_trace.rs`](../../../rust/z/zobrist_position_hash_trace.rs) |
| V | [`v/z/zobrist_position_hash_trace.v`](../../../v/z/zobrist_position_hash_trace.v) |
| Zig | [`zig/z/zobrist_position_hash_trace.zig`](../../../zig/z/zobrist_position_hash_trace.zig) |

The ten ports are registered with the `i64_array_bytes_output` runner and
verifier. No executable checks were run.
