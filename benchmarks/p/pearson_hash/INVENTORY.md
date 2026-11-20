# Static source inventory

The Pearson hash ABI is `pearson_hash(input, input_length) -> i64` with the
frame documented in [`README.md`](README.md). The `T` validation and byte
domain are part of the call contract. [`verify_workload.py`](verify_workload.py)
materializes the compact workload cases and compares both references. Package-local
static source inventory:

| Language | Source |
| --- | --- |
| C | [`c/p/pearson_hash.c`](../../../c/p/pearson_hash.c) |
| C++ | [`cpp/p/pearson_hash.cpp`](../../../cpp/p/pearson_hash.cpp) |
| Rust | [`rust/p/pearson_hash.rs`](../../../rust/p/pearson_hash.rs) |
| Zig | [`zig/p/pearson_hash.zig`](../../../zig/p/pearson_hash.zig) |
| Nim | [`nim/p/pearson_hash.nim`](../../../nim/p/pearson_hash.nim) |
| Odin | [`odin/p/pearson_hash.odin`](../../../odin/p/pearson_hash.odin) |
| V | [`v/p/pearson_hash.v`](../../../v/p/pearson_hash.v) |
| Mojo | [`mojo/p/pearson_hash.mojo`](../../../mojo/p/pearson_hash.mojo) |
| Elisa | [`elisa/p/pearson_hash.elisa`](../../../elisa/p/pearson_hash.elisa) |
| C3 | [`c3/p/pearson_hash.c3`](../../../c3/p/pearson_hash.c3) |

Suite runner and shared catalog registration are intentionally outside this
package-local draft.
