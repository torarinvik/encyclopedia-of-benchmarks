# Small-to-large subtree color mode sum

For every vertex in a rooted tree, return the sum of the color labels whose
frequency is maximal in that vertex's subtree. Ties contribute every tied
label. Colors are signed integers in `[-1000,1000]`.

Input is `[N,parent[1..N-1],color[0..N-1]]`. The root is vertex 0,
`1 <= N <= 64`, and `0 <= parent[v] < v`, so the parent list defines a rooted
tree and a reverse vertex scan is a postorder. The exact input length is
`2*N`, with 128 valid words and 129 parseable words maximum. Invalid or null
input returns `-1`. Output is one signed 64-bit answer per vertex in vertex
order, encoded as little-endian bytes. A null output pointer or capacity below
`8*N` returns `-2` without writing; malformed input takes precedence. The
maximum output is 512 bytes and every answer is in `[-64000,64000]`.

The implementation stores a frequency map per processed subtree. At each
vertex it keeps the largest child's map, inserts all entries from smaller
child maps, then inserts the vertex color. Map rows are owned by one subtree
at a time and are reused upward after that subtree's answer has been saved.
Colors are compressed once; each map keeps a list of present color indices and
a direct frequency row. Thus each merge visits only colors present in the
smaller maps. The bounded implementation uses `O(N^2)` storage and at most
`O(N^2 log N)` map-entry visits; the direct array-backed map update is O(1).
Its conservative per-call local scratch budget is 72 KiB, separate from the
maximum 512-byte output buffer.

[`mode`](../../m/mode/README.md) finds a mode for one flat array, while
[`tree_subtree_distinct_sack`](../tree_subtree_distinct_sack/README.md) uses a
single mutable counter table with heavy-child retention and replay. This
profile merges separately owned per-subtree frequency maps and returns the
sum of all modal labels, so it exercises a different merge strategy and
aggregation.

The [SOI Smaller to Larger chapter](https://soi.ch/wiki/smaller-to-larger/)
describes retaining the largest child map and moving entries from smaller
maps. It is used for algorithm identification only. The bounded contract,
fixtures, references, and ten language ports are independently written; no
source code, problem text, or examples were copied. See [`RIGHTS.md`](RIGHTS.md).

The primary oracle uses small-to-large frequency-map merges. The independent
oracle climbs parent chains to classify descendants, then builds each
subtree's histogram directly. Workload cases cover singleton and tied modes,
negative labels, stars and chains, malformed frames, and output-buffer errors.
The sources have not been compiled or executed.

| Language | Source |
|---|---|
| C | [c/s/small_to_large_subtree_color_mode_sum.c](../../../c/s/small_to_large_subtree_color_mode_sum.c) |
| C3 | [c3/s/small_to_large_subtree_color_mode_sum.c3](../../../c3/s/small_to_large_subtree_color_mode_sum.c3) |
| C++ | [cpp/s/small_to_large_subtree_color_mode_sum.cpp](../../../cpp/s/small_to_large_subtree_color_mode_sum.cpp) |
| Elisa | [elisa/s/small_to_large_subtree_color_mode_sum.elisa](../../../elisa/s/small_to_large_subtree_color_mode_sum.elisa) |
| Mojo | [mojo/s/small_to_large_subtree_color_mode_sum.mojo](../../../mojo/s/small_to_large_subtree_color_mode_sum.mojo) |
| Nim | [nim/s/small_to_large_subtree_color_mode_sum.nim](../../../nim/s/small_to_large_subtree_color_mode_sum.nim) |
| Odin | [odin/s/small_to_large_subtree_color_mode_sum.odin](../../../odin/s/small_to_large_subtree_color_mode_sum.odin) |
| Rust | [rust/s/small_to_large_subtree_color_mode_sum.rs](../../../rust/s/small_to_large_subtree_color_mode_sum.rs) |
| V | [v/s/small_to_large_subtree_color_mode_sum.v](../../../v/s/small_to_large_subtree_color_mode_sum.v) |
| Zig | [zig/s/small_to_large_subtree_color_mode_sum.zig](../../../zig/s/small_to_large_subtree_color_mode_sum.zig) |
