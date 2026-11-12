# Frequency table of tree distances

For every distance `d` from 1 through `N-1`, count the unordered vertex pairs
whose unique path has exactly `d` edges. The implementation uses centroid
decomposition: each pair is counted at the first centroid that separates its
endpoints. At a centroid, depth-frequency tables from different child
components are combined, including depth zero for the centroid itself.

## Contract

The bounded ABI encodes `[N,(u,v)...]`, with `1 <= N <= 64`. The `N-1`
undirected edges must form a tree. A successful call writes `N-1` signed
64-bit little-endian pair counts in increasing distance order. For `N=1`, it
writes zero bytes and returns zero. Invalid input returns `-1`; a null output
buffer or insufficient capacity returns `-2` without writing. The maximum
input is 127 integers and the maximum output/workspace is 504 bytes. Here
`workspace.bytes=504` records output-buffer capacity; adjacency and decomposition
storage are separate.

The bounded profile stores adjacency as a matrix and combines depth
frequencies directly, giving `O(N^2 log N)` worst-case work. The official task
permits `N <= 200000`; this smaller profile keeps every language
implementation bounded while preserving centroid-based pair counting.

## Distinctness

The local [`centroid_decomposition`](../../c/centroid_decomposition/README.md)
benchmark only constructs the centroid-parent tree. It does not count vertex
pairs by distance. The all-pairs shortest-path packages return distances for
general weighted graphs, while this task returns a histogram for an unweighted
tree and uses centroid decomposition to count each unordered pair once.

Official contract: [Library Checker — Frequency Table of Tree Distance](https://github.com/yosupo06/library-checker-problems/blob/master/tree/frequency_table_of_tree_distance/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/tree/frequency_table_of_tree_distance/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers a singleton, a two-vertex tree, a path,
a star, a balanced tree, malformed cyclic input, and insufficient capacity.
The independent [`benchmarks/frequency_table_of_tree_distance_oracle.py`](../../frequency_table_of_tree_distance_oracle.py)
uses direct BFS from every vertex and counts each unordered pair once.

## Implementations

| Language | Port |
|---|---|
| C | [`c/f/frequency_table_of_tree_distance.c`](../../../c/f/frequency_table_of_tree_distance.c) |
| C3 | [`c3/f/frequency_table_of_tree_distance.c3`](../../../c3/f/frequency_table_of_tree_distance.c3) |
| C++ | [`cpp/f/frequency_table_of_tree_distance.cpp`](../../../cpp/f/frequency_table_of_tree_distance.cpp) |
| Elisa | [`elisa/f/frequency_table_of_tree_distance.elisa`](../../../elisa/f/frequency_table_of_tree_distance.elisa) |
| Nim | [`nim/f/frequency_table_of_tree_distance.nim`](../../../nim/f/frequency_table_of_tree_distance.nim) |
| Odin | [`odin/f/frequency_table_of_tree_distance.odin`](../../../odin/f/frequency_table_of_tree_distance.odin) |
| Rust | [`rust/f/frequency_table_of_tree_distance.rs`](../../../rust/f/frequency_table_of_tree_distance.rs) |
| V | [`v/f/frequency_table_of_tree_distance.v`](../../../v/f/frequency_table_of_tree_distance.v) |
| Zig | [`zig/f/frequency_table_of_tree_distance.zig`](../../../zig/f/frequency_table_of_tree_distance.zig) |
| Mojo | [`mojo/f/frequency_table_of_tree_distance.mojo`](../../../mojo/f/frequency_table_of_tree_distance.mojo) |
