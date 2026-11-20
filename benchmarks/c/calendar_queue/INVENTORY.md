# Static inventory

ABI symbol: `calendar_queue`, family `i64_array_bytes_output`. The profile
contract is in [`README.md`](README.md); workload and bounds are in
[`workload.json`](workload.json). No source has been compiled or executed.

| Language | Source |
| --- | --- |
| C | [`c/calendar_queue.c`](../../../c/c/calendar_queue.c) |
| C3 | [`c3/c/calendar_queue.c3`](../../../c3/c/calendar_queue.c3) |
| C++ | [`cpp/c/calendar_queue.cpp`](../../../cpp/c/calendar_queue.cpp) |
| Elisa | [`elisa/c/calendar_queue.elisa`](../../../elisa/c/calendar_queue.elisa) |
| Mojo | [`mojo/c/calendar_queue.mojo`](../../../mojo/c/calendar_queue.mojo) |
| Nim | [`nim/c/calendar_queue.nim`](../../../nim/c/calendar_queue.nim) |
| Odin | [`odin/c/calendar_queue.odin`](../../../odin/c/calendar_queue.odin) |
| Rust | [`rust/c/calendar_queue.rs`](../../../rust/c/calendar_queue.rs) |
| V | [`v/c/calendar_queue.v`](../../../v/c/calendar_queue.v) |
| Zig | [`zig/c/calendar_queue.zig`](../../../zig/c/calendar_queue.zig) |

References: [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py). Static source inventory:
[`INVENTORY.json`](INVENTORY.json).

The workload's maximum-live fixture reaches 64 active events before its first
dequeue; with the strict `live > 2 * bucket_count` growth rule, the largest
reached calendar has 32 buckets.
