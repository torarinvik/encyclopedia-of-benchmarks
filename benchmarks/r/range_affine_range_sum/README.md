# Range affine range sum

This benchmark implements a lazy segment tree over the finite field modulo
998,244,353. An update applies `x <- a*x+b` to every value in a half-open
range; a query returns the modular sum over a half-open range. The lazy action
stores and composes affine tags, while each tree node stores the range sum.

## Contract

The `i64_array_scalar` input is
`[n, values[n], q, operations...]`, with `1 <= n <= 64`, `1 <= q <= 64`,
initial values and affine offsets in `[0, 998244353)`, and affine multipliers
in `[1, 998244353)`. Each update
is `[0, left, right, a, b]` and transforms each covered value to
`(a*x+b) mod 998244353`. Each query is `[1, left, right]` and observes the sum
modulo 998,244,353. Ranges are half-open and satisfy `0 <= left < right <= n`,
matching the official task. Unknown operations, out-of-range values, truncated
records, and trailing input return `-1`.

For a query result `s` at zero-based operation position `i`, the scalar result
adds `(i+1)*(s+998244353)`. Updates contribute no checksum term but still
advance the operation position. The maximum valid input frame is 386 signed
64-bit values; ports accept at most 387 values to recognize malformed
oversized input. Intermediate modular products fit in signed 64-bit
arithmetic: each product is below `(998244353-1)^2`, and the update of a
segment sum reduces only after adding at most `64*(998244352)`.

## Algorithm and distinctness

The tree uses the usual lazy-propagation recurrence. For a node with sum `S`
and length `len`, applying `(a,b)` changes its sum to `(a*S+b*len) mod M`.
If the old pending map is `(u,v)`, the new pending map is
`(a*u, a*v+b) mod M`, preserving the order of updates. This is the full
affine-update/range-sum operation from the Library Checker task, not just the
range-multiplication/sum profile in `segment_tree_apply` or the additive-only
profile in `lazy_segment_tree_range_add_sum`.

The bounded workload uses a recursive segment tree with `O(n)` storage and
`O(log n)` work per update or query. The direct-array oracle applies updates
element by element in `O(n)` and therefore does not share the tree's lazy-tag
logic.

## Provenance and rights

The operation contract is based on the official Library Checker
[`range_affine_range_sum` task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_affine_range_sum/task.md)
and its
[`info.toml` limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/range_affine_range_sum/info.toml).
The language ports and oracle are clean-room implementations from the task
semantics. No upstream implementation code is copied into this package.
The source-reference and licensing note is in [`RIGHTS.md`](RIGHTS.md).

## Workload and oracle

[`workload.json`](workload.json) pins the bounded cases and measurement
metadata. The independent direct-array oracle is
[`benchmarks/range_affine_range_sum_oracle.py`](../../range_affine_range_sum_oracle.py);
the package-local static checker is
[`benchmarks/range_affine_range_sum_verifier.py`](../../range_affine_range_sum_verifier.py).

## Implementations

| Language | Port |
|---|---|
| C | [`c/r/range_affine_range_sum.c`](../../../c/r/range_affine_range_sum.c) |
| C3 | [`c3/r/range_affine_range_sum.c3`](../../../c3/r/range_affine_range_sum.c3) |
| C++ | [`cpp/r/range_affine_range_sum.cpp`](../../../cpp/r/range_affine_range_sum.cpp) |
| Elisa | [`elisa/r/range_affine_range_sum.elisa`](../../../elisa/r/range_affine_range_sum.elisa) |
| Mojo | [`mojo/r/range_affine_range_sum.mojo`](../../../mojo/r/range_affine_range_sum.mojo) |
| Nim | [`nim/r/range_affine_range_sum.nim`](../../../nim/r/range_affine_range_sum.nim) |
| Odin | [`odin/r/range_affine_range_sum.odin`](../../../odin/r/range_affine_range_sum.odin) |
| Rust | [`rust/r/range_affine_range_sum.rs`](../../../rust/r/range_affine_range_sum.rs) |
| V | [`v/r/range_affine_range_sum.v`](../../../v/r/range_affine_range_sum.v) |
| Zig | [`zig/r/range_affine_range_sum.zig`](../../../zig/r/range_affine_range_sum.zig) |
