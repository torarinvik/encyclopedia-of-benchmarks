# Undirected feedback vertex set by iterative compression

This bounded exact profile follows the chapter's iterative-compression method.
For each vertex-prefix graph, it forms a size-at-most-`k+1` feedback vertex set
from the previous prefix solution plus the newly added vertex. When that set is
too large, the compression search partitions it into included `X` and excluded
`Y`, then exhaustively searches additional vertices `S` outside the candidate
set. A candidate `X ∪ S` is accepted only when deleting it leaves a forest.
The bounded profile uses `1 <= n <= 8`, `0 <= k <= 4`; each compression search
examines every subset permitted by `|X|+|S| <= k`. This keeps the source method
exact while making all bounds explicit.

Input is `[n,m,k,(u,v)...]`. Edges form a simple undirected graph and must be
given once in strictly increasing order with `u < v`. Output is
`[has_feedback_vertex_set_of_size_at_most_k, minimum_size_if_found_else_-1]`
as two little-endian signed i64 values. The minimum witness is found by trying
budgets in increasing order. Invalid input returns `-1`; null output or a
capacity below 16 bytes returns `-2` without writing.

Source: “Undirected Feedback Vertex Set,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_450`](https://doi.org/10.1007/978-1-4939-2864-4_450).
The ports and documentation are clean-room; no book prose, pseudocode blocks,
or code were copied.

## Ports

| Language | Port |
|---|---|
| C | `c/u/undirected_feedback_vertex_set.c` |
| C3 | `c3/u/undirected_feedback_vertex_set.c3` |
| C++ | `cpp/u/undirected_feedback_vertex_set.cpp` |
| Elisa | `elisa/u/undirected_feedback_vertex_set.elisa` |
| Nim | `nim/u/undirected_feedback_vertex_set.nim` |
| Odin | `odin/u/undirected_feedback_vertex_set.odin` |
| Rust | `rust/u/undirected_feedback_vertex_set.rs` |
| V | `v/u/undirected_feedback_vertex_set.v` |
| Zig | `zig/u/undirected_feedback_vertex_set.zig` |

Primary oracle: `benchmarks/undirected_feedback_vertex_set_oracle.py`.
Independent subset-enumeration verifier:
`benchmarks/undirected_feedback_vertex_set_verifier_oracle.py`.
