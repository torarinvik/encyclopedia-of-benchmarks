# Additive 2-spanner completion

This package implements the 2-spanner-completion algorithm for simple,
unweighted, undirected graphs, starting from the empty subgraph. It repeatedly
finds the lexicographically first vertex pair whose current subgraph distance
exceeds the input distance by more than two, then adds a shortest input-graph
path for that pair. The completed subgraph preserves every finite input
distance with additive error at most two.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `additive_two_spanner_completion`.
- Input is `[n,m,(u,v)*m]`, with `1<=n<=8`, `0<=m<=28`, normalized endpoints
  `0<=u<v<n`, and no duplicate edges. Disconnected inputs are allowed.
- At each iteration, scan vertex pairs in increasing `(u,v)` order. Select the
  first violating pair, and add its lexicographically smallest shortest path
  in the input graph (neighbors in increasing vertex order). Repeat until no
  pair violates additive stretch two. Output selected input edges in their
  original record order.
- This follows Knudsen's empty-start 2-spanner completion construction. Pair
  order and shortest-path ties are deterministic local profile choices.
- Invalid input returns `-1`; null or short output returns `-2` and leaves the
  output untouched. Maximum input and parseable lengths are 58 and 59 words;
  maximum output is 456 bytes.
- With at most `m` completion rounds, the current straightforward path
  reconstruction takes `O((m+1)(n^3+n^2m))` time and `O(n^2+m)` auxiliary
  storage.

The primary reference uses BFS distance rows; the independent reference uses
Floyd–Warshall distances. Both independently reconstruct the deterministic
first-violating-pair profile. Fixtures cover connected and disconnected
graphs, empty graphs, framing, null buffers, and capacity failures.

## Source and rights

The chapter [“Additive Spanners”](https://doi.org/10.1007/978-1-4939-2864-4_562)
surveys several additive-spanner constructions. This specific profile follows
Mathias Bæk Tejs Knudsen, [“Additive Spanners: A Simple Construction,” §1 and
§3](https://doi.org/10.1007/978-3-319-08404-6_24), which defines the completion
loop and the empty-start additive-2 case. The source is used for algorithm
ideas only; no code, prose, examples, or test data are copied. See
[RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/a/additive_two_spanner_completion.c`](../../../c/a/additive_two_spanner_completion.c) |
| C3 | [`c3/a/additive_two_spanner_completion.c3`](../../../c3/a/additive_two_spanner_completion.c3) |
| C++ | [`cpp/a/additive_two_spanner_completion.cpp`](../../../cpp/a/additive_two_spanner_completion.cpp) |
| Elisa | [`elisa/a/additive_two_spanner_completion.elisa`](../../../elisa/a/additive_two_spanner_completion.elisa) |
| Mojo | [`mojo/a/additive_two_spanner_completion.mojo`](../../../mojo/a/additive_two_spanner_completion.mojo) |
| Nim | [`nim/a/additive_two_spanner_completion.nim`](../../../nim/a/additive_two_spanner_completion.nim) |
| Odin | [`odin/a/additive_two_spanner_completion.odin`](../../../odin/a/additive_two_spanner_completion.odin) |
| Rust | [`rust/a/additive_two_spanner_completion.rs`](../../../rust/a/additive_two_spanner_completion.rs) |
| V | [`v/a/additive_two_spanner_completion.v`](../../../v/a/additive_two_spanner_completion.v) |
| Zig | [`zig/a/additive_two_spanner_completion.zig`](../../../zig/a/additive_two_spanner_completion.zig) |

See [workload.json](workload.json), both references, and the static package
inventory [verify_workload.py](verify_workload.py).
