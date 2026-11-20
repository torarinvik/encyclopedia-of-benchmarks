# Tree center by rerooting DP

This profile returns the one or two vertices of an unweighted tree minimizing
the maximum distance to every other vertex. It uses a rooted postorder to find
the two best downward branch heights at every vertex, then a preorder to
propagate the best distance that leaves each subtree. It is algorithmically
distinct from [`tree_center`](../tree_center/README.md), which peels leaf
layers.

## Contract

The `i64_array_bytes_output` symbol is `tree_center_rerooting_dp`. Input is
`[N,(u,v)...]`, with `1 <= N <= 64` and exactly `N-1` undirected edges. The
edges must form a simple connected tree. Malformed input returns `-1`; a
successful result writes one or two ascending little-endian signed 64-bit
vertex IDs and returns 8 or 16 bytes. Null or undersized output returns `-2`
without writes. The maximum valid and parseable input lengths are both 127
words; maximum output is 16 bytes.

Tree validation, the two DP passes, and center selection take `O(N+M)` time.
The bounded neighbor matrix and per-vertex state use `O(N^2)` storage; the
contract caps `N` at 64.

## References and workload

The primary method reference is [`primary_oracle.py`](primary_oracle.py). The
independent expected-output reference computes every eccentricity using BFS
from every vertex in [`independent_oracle.py`](independent_oracle.py). The
workload covers singleton and two-node trees, odd/even paths, branching trees,
malformed frames, and output-buffer errors.

The algorithm idea comes from the OI Wiki
[`tree center` article](https://oi-wiki.org/graph/tree-center/); no source code,
text, examples, or tests were reused. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/t/tree_center_rerooting_dp.c`](../../../c/t/tree_center_rerooting_dp.c) |
| C3 | [`c3/t/tree_center_rerooting_dp.c3`](../../../c3/t/tree_center_rerooting_dp.c3) |
| C++ | [`cpp/t/tree_center_rerooting_dp.cpp`](../../../cpp/t/tree_center_rerooting_dp.cpp) |
| Elisa | [`elisa/t/tree_center_rerooting_dp.elisa`](../../../elisa/t/tree_center_rerooting_dp.elisa) |
| Mojo | [`mojo/t/tree_center_rerooting_dp.mojo`](../../../mojo/t/tree_center_rerooting_dp.mojo) |
| Nim | [`nim/t/tree_center_rerooting_dp.nim`](../../../nim/t/tree_center_rerooting_dp.nim) |
| Odin | [`odin/t/tree_center_rerooting_dp.odin`](../../../odin/t/tree_center_rerooting_dp.odin) |
| Rust | [`rust/t/tree_center_rerooting_dp.rs`](../../../rust/t/tree_center_rerooting_dp.rs) |
| V | [`v/t/tree_center_rerooting_dp.v`](../../../v/t/tree_center_rerooting_dp.v) |
| Zig | [`zig/t/tree_center_rerooting_dp.zig`](../../../zig/t/tree_center_rerooting_dp.zig) |

`verify_workload.py` statically checks fixture framing and the ten-port
inventory. The byte-output runner uses the rerooting-DP primary reference; the
suite verifier uses the independent all-sources BFS reference.
