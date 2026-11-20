# Wilson uniform spanning tree trace

This package replays Wilson's rooted uniform-spanning-tree algorithm on a
small connected, undirected, simple graph. It starts with the chosen root in
the tree, then processes every other vertex in ascending ID order. For each
start, it performs a simple random walk until reaching the current tree. The
successor of a revisited vertex is overwritten, which erases the loop; the
remaining successor chain is then added to the tree.

## Bounded replay contract

Input is `[n,m,root,(u,v)*m,q,draws[q]]`. Require `1<=n<=8`,
`0<=m<=28`, `0<=root<n`, and a connected simple graph. Each edge must be
`u<v`; edge pairs must be strictly lexicographically increasing. Let
`q<=64*(n-1)`. Each draw is an integer in `0..6`, interpreted as a
zero-based ordinal in the current vertex's neighbors sorted by vertex ID;
when consumed it must also be smaller than that current degree. Every walk
has a 64-draw cap. The trace is invalid if a walk needs another step after
64 draws, the tape ends before the tree is reached, any consumed neighbor
ordinal is out of range, or the algorithm finishes with unused tape entries.
For `n=1`, `root=0`, `m=0`, and `q=0` is valid and returns an empty output.

On success, output is a sequence of `(child,parent)` pairs, one for every
non-root vertex, ordered by ascending child ID. Each integer is an eight-byte
little-endian i64. The maximum output is 112 bytes. A 508-word valid-frame
bound and a 509-word parse bound cover the declared graph and tape limits;
workspace is capped at 2,048 bytes. Invalid input returns `-1`. After the
entire graph and walk tape have been validated and consumed, null output or
insufficient capacity returns `-2` without writes. The valid one-vertex
case needs zero output bytes and accepts a null output pointer.

Draws are caller supplied for repeatability. The profile tests deterministic
walk traces; it does not claim a probability distribution for an arbitrary
fixed tape. With independently uniform valid neighbor choices, the pinned
Wilson procedure is the uniform spanning-tree algorithm described by the
source.

The primary reference follows Wilson's successor-pointer construction. The
independent reference stores each complete random walk first, then erases
loops by repeatedly following the last occurrence of the current path vertex
in that stored walk. The independent reference also checks connectivity by
transitive closure rather than traversal.

## Duplicate comparison

This is different from minimum spanning tree algorithms, which optimize
deterministic edge weights; spanning-tree counting, which returns a count;
and `tree_random_walk_edge_hitting_cost`, which computes expected weighted
walk costs on a supplied tree. None constructs a rooted spanning tree by
joining loop-erased walks.

## Source and rights

The algorithm follows David B. Wilson, [“Generating Random Spanning Trees
More Quickly than the Cover Time”](https://doi.org/10.1145/237814.237880),
STOC 1996, Figure 1 (`RandomTreeWithRoot`), also available as an
[author-hosted PDF](https://www.cs.cmu.edu/~15859n/RelatedWork/RandomTrees-Wilson.pdf).
See [RIGHTS.md](RIGHTS.md) for provenance and reuse details.

## Language ports

| Language | Source |
|---|---|
| C | [`c/w/wilson_uniform_spanning_tree.c`](../../../c/w/wilson_uniform_spanning_tree.c) |
| C3 | [`c3/w/wilson_uniform_spanning_tree.c3`](../../../c3/w/wilson_uniform_spanning_tree.c3) |
| C++ | [`cpp/w/wilson_uniform_spanning_tree.cpp`](../../../cpp/w/wilson_uniform_spanning_tree.cpp) |
| Elisa | [`elisa/w/wilson_uniform_spanning_tree.elisa`](../../../elisa/w/wilson_uniform_spanning_tree.elisa) |
| Mojo | [`mojo/w/wilson_uniform_spanning_tree.mojo`](../../../mojo/w/wilson_uniform_spanning_tree.mojo) |
| Nim | [`nim/w/wilson_uniform_spanning_tree.nim`](../../../nim/w/wilson_uniform_spanning_tree.nim) |
| Odin | [`odin/w/wilson_uniform_spanning_tree.odin`](../../../odin/w/wilson_uniform_spanning_tree.odin) |
| Rust | [`rust/w/wilson_uniform_spanning_tree.rs`](../../../rust/w/wilson_uniform_spanning_tree.rs) |
| V | [`v/w/wilson_uniform_spanning_tree.v`](../../../v/w/wilson_uniform_spanning_tree.v) |
| Zig | [`zig/w/wilson_uniform_spanning_tree.zig`](../../../zig/w/wilson_uniform_spanning_tree.zig) |

The workload, two references, rights note, and inventory checker are package
artifacts. Shared `i64_array_bytes_output` runner/verifier and catalog
integration are complete.
