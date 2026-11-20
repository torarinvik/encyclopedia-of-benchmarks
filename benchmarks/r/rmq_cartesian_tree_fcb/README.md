# Static RMQ by Cartesian tree and Farach–Colton–Bender LCA

This package answers static inclusive range-minimum queries by composing a
min Cartesian tree with an Euler-tour Farach–Colton–Bender (FCB) LCA index.
Each query `[l,r]` returns the leftmost index of the minimum value in that
range. Exact indices are returned in a count-prefixed byte vector.

## Contract

The `i64_array_bytes_output` input is `[n,q,values[n],(left,right)*q]`.
`1<=n<=64`, `0<=q<=64`, values are in `[-1000,1000]`, and each inclusive
query satisfies `0<=left<=right<n`. Input length is exactly `2+n+2q`; the
maximum valid frame is 194 signed 64-bit words. A single parseable trailing
word is allowed by the 195-word parse limit but makes the input invalid.
Invalid or out-of-profile input returns `-1`. The workload pins explicit input
lengths and includes the maximum 194-word call, its full 65-byte output, and a
195-word trailing-word rejection case.

Output is `[q,answer_0,...,answer_(q-1)]`, each byte an unsigned leftmost
minimum index. It always needs `q+1` bytes, including one byte for an empty
query batch. A null output or capacity below `q+1` returns `-2`; errors leave
the output untouched. Maximum output is 65 bytes. Input validation precedes
output-buffer validation.

## Method and distinction

The primary builds the min Cartesian tree with a right-spine monotone stack.
Strictly greater values are popped, so equal minima retain the earlier index
as ancestor. It then walks the tree to form an Euler tour whose adjacent
depths differ by one. The first occurrences of the queried array positions
turn each RMQ into an LCA. FCB encodes each short Euler block by its up/down
signature, answers partial blocks through a microtable, and uses a sparse
table over whole-block minima. Preprocessing and storage are `O(n)` for this
bounded profile, and each query is `O(1)`. The independent oracle directly
scans every requested interval.

The local [`cartesian_tree`](../../c/cartesian_tree/README.md) package only
constructs the parent array, while
[`lowest_common_ancestor_farach_colton_bender`](../../l/lowest_common_ancestor_farach_colton_bender/README.md)
answers LCA queries on an explicitly supplied tree. This profile joins those
steps to solve RMQ from the original array. It is distinct from sparse-table
overlapping blocks, the Sqrt Tree hierarchy, and Arpa's DSU sweep.

The algorithm description comes from CP-Algorithms,
[“Solve RMQ by finding LCA”](https://cp-algorithms.com/graph/rmq_linear.html),
CC BY-SA 4.0. No upstream code or test data is used. See [RIGHTS.md](RIGHTS.md),
[`workload.json`](workload.json), the [primary reference](primary_oracle.py),
the [direct-scan reference](independent_oracle.py), and the source-only
[inventory](INVENTORY.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/rmq_cartesian_tree_fcb.c`](../../../c/rmq_cartesian_tree_fcb.c) |
| C3 | [`c3/r/rmq_cartesian_tree_fcb.c3`](../../../c3/rmq_cartesian_tree_fcb.c3) |
| C++ | [`cpp/r/rmq_cartesian_tree_fcb.cpp`](../../../cpp/rmq_cartesian_tree_fcb.cpp) |
| Elisa | [`elisa/r/rmq_cartesian_tree_fcb.elisa`](../../../elisa/r/rmq_cartesian_tree_fcb.elisa) |
| Mojo | [`mojo/r/rmq_cartesian_tree_fcb.mojo`](../../../mojo/r/rmq_cartesian_tree_fcb.mojo) |
| Nim | [`nim/r/rmq_cartesian_tree_fcb.nim`](../../../nim/r/rmq_cartesian_tree_fcb.nim) |
| Odin | [`odin/r/rmq_cartesian_tree_fcb.odin`](../../../odin/r/rmq_cartesian_tree_fcb.odin) |
| Rust | [`rust/r/rmq_cartesian_tree_fcb.rs`](../../../rust/r/rmq_cartesian_tree_fcb.rs) |
| V | [`v/r/rmq_cartesian_tree_fcb.v`](../../../v/r/rmq_cartesian_tree_fcb.v) |
| Zig | [`zig/r/rmq_cartesian_tree_fcb.zig`](../../../zig/r/rmq_cartesian_tree_fcb.zig) |
