# Static package inventory

ABI: `i64_array_bytes_output`; symbol:
`k_quadtree_edge_distribution(input, length, output, capacity)`.
Input bound: 126 valid / 127 parseable signed-i64 words. Output bound: 376
bytes. Workspace bound: 16,384 bytes, excluding caller buffers. The
conservative live-array estimate for the widest 64-bit-index ports is about
10.9 KiB: parser state, sweep order/edge/stack/candidate arrays, and nested
frontier atom/rank/path arrays can coexist during the stack sweep. The rounded
cap leaves room for scalar temporaries, alignment, and ABI-local bookkeeping.

References: [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). Static metadata helpers:
[`verify_workload.py`](verify_workload.py) and
[`check_inventory.py`](check_inventory.py). They are included for static
review and have not been run.

| Language | Source |
| --- | --- |
| C | [`c/k/k_quadtree_edge_distribution.c`](../../../c/k/k_quadtree_edge_distribution.c) |
| C3 | [`c3/k/k_quadtree_edge_distribution.c3`](../../../c3/k/k_quadtree_edge_distribution.c3) |
| C++ | [`cpp/k/k_quadtree_edge_distribution.cpp`](../../../cpp/k/k_quadtree_edge_distribution.cpp) |
| Elisa | [`elisa/k/k_quadtree_edge_distribution.elisa`](../../../elisa/k/k_quadtree_edge_distribution.elisa) |
| Mojo | [`mojo/k/k_quadtree_edge_distribution.mojo`](../../../mojo/k/k_quadtree_edge_distribution.mojo) |
| Nim | [`nim/k/k_quadtree_edge_distribution.nim`](../../../nim/k/k_quadtree_edge_distribution.nim) |
| Odin | [`odin/k/k_quadtree_edge_distribution.odin`](../../../odin/k/k_quadtree_edge_distribution.odin) |
| Rust | [`rust/k/k_quadtree_edge_distribution.rs`](../../../rust/k/k_quadtree_edge_distribution.rs) |
| V | [`v/k/k_quadtree_edge_distribution.v`](../../../v/k/k_quadtree_edge_distribution.v) |
| Zig | [`zig/k/k_quadtree_edge_distribution.zig`](../../../zig/k/k_quadtree_edge_distribution.zig) |

The clean-room profiles validate complete canonical partitions and planar
general-position edge inputs, then emit one incidence mask per supplied cell.
