# Range affine point get

This benchmark applies modular affine transformations to half-open ranges of
an array and reads individual elements. The ports use a lazy segment tree whose
nodes store pending affine maps. A partial update pushes a node's map to its
children before descending; this preserves chronological composition when later
updates cover smaller or larger ranges.

## Contract

The input is a signed 64-bit integer array containing
`[N,Q,initial_values...,variable_length_operations...]`. The modulus is
998244353. Each initial value and affine offset `c` is in `[0, MOD)`, and each
multiplier `b` is in `[1, MOD)`. Operation `0,l,r,b,c` applies
`a[j] = b*a[j] + c (mod MOD)` for every `l <= j < r`; operation `1,i` reads
`a[i]`. The local bounds are `1 <= N <= 256` and `0 <= Q <= 256`, with
`0 <= l < r <= N` and `0 <= i < N`. Unknown operations, invalid coefficients,
invalid ranges, truncated records, trailing values, and inputs outside the
declared signed 64-bit domain return `-1`.

Successful calls write one signed 64-bit little-endian value for each point
read, in operation order, and return the byte count. Invalid input returns
`-1`; null or insufficient output for a nonempty result returns `-2` without
writing. A query-free trace succeeds with zero output bytes. The maximum valid
input is 1,538 integers; one extra parseable integer is reserved to detect
trailing input. At most 256 results require a 2,048-byte output buffer.

The tree is padded to a power of two. Each node stores a pending map
`x -> mul*x + add`. If a new map `(b,c)` is applied after an existing map
`(mul,add)`, the stored map becomes `(b*mul, b*add+c) mod MOD`. Both updates
and point reads take `O(log N)` time; storage is `O(N)`.

## Relationship to existing range workloads

[`segment_tree_apply`](../../s/segment_tree_apply/README.md) uses inclusive
range multiplication with range-sum observations over small signed values; it
does not apply affine offsets or query individual modular values. The assigned
[`range_affine_range_sum`](../range_affine_range_sum/README.md) profile shares
the affine update law but maintains range aggregates. This profile isolates
point observations and stores only lazy transformation tags, with no aggregate
at internal nodes.

The [official Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_affine_point_get/task.md)
allows `N,Q <= 500,000` and uses the same modulus and operation semantics. This
package uses smaller fixed bounds for a predictable cross-language benchmark.
The task repository is Apache-2.0. This package uses the task name and contract
as provenance and contains clean-room implementations; it does not copy
upstream source code or tests. See [`RIGHTS.md`](RIGHTS.md) for the provenance
and rights note.

## Workload and oracle

[`workload.json`](workload.json) includes nested and overlapping updates,
composition-order checks, point reads, an empty operation stream, malformed
records, invalid coefficients, and output-capacity handling. The independent
[`range_affine_point_get_oracle.py`](../../range_affine_point_get_oracle.py)
updates a plain array directly and does not use a segment tree.

## Implementations

| Language | Source |
|---|---|
| C | [`c/r/range_affine_point_get.c`](../../../c/r/range_affine_point_get.c) |
| C3 | [`c3/r/range_affine_point_get.c3`](../../../c3/r/range_affine_point_get.c3) |
| C++ | [`cpp/r/range_affine_point_get.cpp`](../../../cpp/r/range_affine_point_get.cpp) |
| Elisa | [`elisa/r/range_affine_point_get.elisa`](../../../elisa/r/range_affine_point_get.elisa) |
| Mojo | [`mojo/r/range_affine_point_get.mojo`](../../../mojo/r/range_affine_point_get.mojo) |
| Nim | [`nim/r/range_affine_point_get.nim`](../../../nim/r/range_affine_point_get.nim) |
| Odin | [`odin/r/range_affine_point_get.odin`](../../../odin/r/range_affine_point_get.odin) |
| Rust | [`rust/r/range_affine_point_get.rs`](../../../rust/r/range_affine_point_get.rs) |
| V | [`v/r/range_affine_point_get.v`](../../../v/r/range_affine_point_get.v) |
| Zig | [`zig/r/range_affine_point_get.zig`](../../../zig/r/range_affine_point_get.zig) |
