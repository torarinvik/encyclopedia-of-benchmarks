# Constant-time Sqrt Tree range minimum

This profile builds the power-of-two-layer Sqrt Tree and answers a batch of
static inclusive range-minimum queries. It uses padded, equal-size segments,
per-block prefix/suffix minima, and compact tables for ranges of whole blocks.
Each query chooses its layer from the highest differing bit of `left XOR
right`, then combines at most a suffix, a whole-block table entry, and a
prefix. Query work is O(1).

## Contract

The `i64_array_bytes_output` input is
`[n,q,values[0..n),left_0,right_0,...]`. Require `1<=n<=64`, `0<=q<=64`,
values in `[-1,000,000,000,1,000,000,000]`, and valid inclusive ranges
`0<=left<=right<n`. The frame must have exactly `2+n+2q` words. The valid
maximum is 194 words; 195 words are accepted for framing so a trailing-word
case can be rejected. Invalid input returns `-1`.

For valid input, emit each query minimum as one little-endian signed 64-bit
value in query order and return `8*q`. A null output for nonempty output or
capacity below `8*q` returns `-2` without writes. Zero queries return zero and
allow a null output pointer. Maximum output is 512 bytes. The fixed workspace
reservation is 8,192 bytes; it covers the padded values, layer summaries,
compact whole-block tables, and lookup state. The caller-owned output buffer
is separate from this workspace.

Let `N` be the padded power-of-two length and `s` a layer's segment bit width.
The child block has `2^ceil(s/2)` elements and there are `2^floor(s/2)` blocks
per segment. The primary stores prefix and suffix minima for each active
element and whole-block interval minima in a compact per-layer table. For
query endpoints that differ at bit `d>0`, a small precomputed map selects the
unique layer with `ceil(s/2)<=d<s`; the endpoints then lie in separate child
blocks of the same segment. If `d=0`, the endpoints are adjacent and are
answered directly. Padding uses positive infinity and cannot affect a valid
query. Construction takes O(N log log N) time and active summary storage;
query time is O(1).

The local [`sqrt_tree`](../sqrt_tree/README.md) package uses recursive
ceil-sqrt partitions and descends through a tree for O(log log n) queries.
This package uses the article's separate equal-power-of-two layout and
bit-selected layer for O(1) queries. The local
[`sparse_table`](../sparse_table/README.md) also answers static RMQ, but stores
overlapping power-of-two intervals with O(n log n) preprocessing/storage;
the Sqrt Tree keeps O(N) active summaries per layer and O(N log log N) across
its layers.

## Sources and artifacts

Primary method description: [CP-Algorithms, Sqrt Tree, “Optimizing the query
complexity”](https://cp-algorithms.com/data_structures/sqrt-tree.html#optimizing-the-query-complexity).
The page is published under CC BY-SA 4.0; only its algorithm description was
used. Implementations and fixtures are clean-room. See [`RIGHTS.md`](RIGHTS.md).

The power-of-two hierarchy is implemented in [`primary_oracle.py`](primary_oracle.py).
[`independent_oracle.py`](independent_oracle.py) scans every queried range
directly. Fixtures are in [`workload.json`](workload.json), with a static
workload preflight in [`verify_workload.py`](verify_workload.py) and a source
inventory in [`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/sqrt_tree_constant_time.c`](../../../c/s/sqrt_tree_constant_time.c) |
| C3 | [`c3/s/sqrt_tree_constant_time.c3`](../../../c3/s/sqrt_tree_constant_time.c3) |
| C++ | [`cpp/s/sqrt_tree_constant_time.cpp`](../../../cpp/s/sqrt_tree_constant_time.cpp) |
| Elisa | [`elisa/s/sqrt_tree_constant_time.elisa`](../../../elisa/s/sqrt_tree_constant_time.elisa) |
| Mojo | [`mojo/s/sqrt_tree_constant_time.mojo`](../../../mojo/s/sqrt_tree_constant_time.mojo) |
| Nim | [`nim/s/sqrt_tree_constant_time.nim`](../../../nim/s/sqrt_tree_constant_time.nim) |
| Odin | [`odin/s/sqrt_tree_constant_time.odin`](../../../odin/s/sqrt_tree_constant_time.odin) |
| Rust | [`rust/s/sqrt_tree_constant_time.rs`](../../../rust/s/sqrt_tree_constant_time.rs) |
| V | [`v/s/sqrt_tree_constant_time.v`](../../../v/s/sqrt_tree_constant_time.v) |
| Zig | [`zig/s/sqrt_tree_constant_time.zig`](../../../zig/s/sqrt_tree_constant_time.zig) |

No programs, tests, scripts, checkers, builds, compilers, benchmarks, or
profilers were run while preparing this package.
