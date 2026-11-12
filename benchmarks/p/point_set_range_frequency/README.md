# Point set range frequency

This benchmark maintains a bounded integer sequence under point assignments
and counts occurrences of an exact value in half-open position ranges. The
ports collect every initial and replacement value before processing, sort and
deduplicate that universe, then maintain one Fenwick tree over positions for
each value. A point assignment removes the old position from its value tree
and inserts it into the new value tree; a frequency query subtracts two
prefix counts from the requested value's tree.

## Contract

Input is the signed 64-bit integer array
`[N,Q,initial_values...,variable_length_operations...]`. Local bounds are
`1 <= N <= 64`, `0 <= Q <= 64`, and all initial values, replacement values,
and queried values are in `[0,1,000,000]`. Operation `0,k,v` assigns `v` to
position `k`, where `0 <= k < N`. Operation `1,l,r,x` returns the number of
positions `j` with `l <= j < r` and value `a[j] == x`, where
`0 <= l <= r <= N`. Empty ranges are valid and return zero. Unknown opcodes,
invalid values or indices, truncated operations, trailing input, and inputs
outside signed 64-bit range return `-1`.

Successful calls write one signed 64-bit little-endian count per frequency
query, in operation order, and return the byte count. Invalid input returns
`-1`; null or insufficient output for a nonempty result returns `-2` without
writing. A query-free trace succeeds with zero bytes. The maximum valid input
is 322 integers; one additional parseable integer is reserved to detect
trailing data. At most 64 answers require a 512-byte output buffer.

The compressed value universe has at most `N+Q <= 128` entries. With insertion
sort for bounded coordinate compression and zero-initialization of the dense
table, setup is `O((N+Q)^2 + N(N+Q) + N log N)`; each point assignment or
frequency query takes `O(log N + log(N+Q))` time. The per-value Fenwick table
uses `O(N(N+Q))` words of fixed storage.
This is a bounded data-structure profile, not a claim about the best memory
layout for the official maximum constraints.

The [official Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/point_set_range_frequency/task.md)
allows `N,Q <= 200,000` and values through `10^9`; this package uses smaller
fixed bounds. The upstream problem repository is Apache-2.0. Implementations
here are clean-room ports of the operation contract and data-structure idea;
no upstream code or generated tests are copied. See [RIGHTS.md](RIGHTS.md).

## Relationship to existing packages

[`wavelet_tree`](../../w/wavelet_tree/README.md) handles static sequences and
does not support point assignments. [`frequency_count_list_update`](../../f/frequency_count_list_update/README.md)
reorders requested list items by a frequency policy; it is not a range
frequency query structure. [`point_add_rectangle_sum`](../point_add_rectangle_sum/README.md)
maintains append-only weighted points in a sparse coordinate plane and sums
half-open rectangles, while this profile assigns values at fixed sequence
positions and counts one exact value. Its measured structure is a family of
value-indexed position Fenwick trees.

## Workload and oracle

[`workload.json`](workload.json) includes duplicate values, repeated and
changed assignments, absent query values, empty ranges, malformed frames, and
capacity handling. The independent
[`point_set_range_frequency_oracle.py`](../../point_set_range_frequency_oracle.py)
scans the current array directly for every query rather than using the
Fenwick trees.

## Implementations

| Language | Source |
|---|---|
| C | [`c/p/point_set_range_frequency.c`](../../../c/p/point_set_range_frequency.c) |
| C3 | [`c3/p/point_set_range_frequency.c3`](../../../c3/p/point_set_range_frequency.c3) |
| C++ | [`cpp/p/point_set_range_frequency.cpp`](../../../cpp/p/point_set_range_frequency.cpp) |
| Elisa | [`elisa/p/point_set_range_frequency.elisa`](../../../elisa/p/point_set_range_frequency.elisa) |
| Mojo | [`mojo/p/point_set_range_frequency.mojo`](../../../mojo/p/point_set_range_frequency.mojo) |
| Nim | [`nim/p/point_set_range_frequency.nim`](../../../nim/p/point_set_range_frequency.nim) |
| Odin | [`odin/p/point_set_range_frequency.odin`](../../../odin/p/point_set_range_frequency.odin) |
| Rust | [`rust/p/point_set_range_frequency.rs`](../../../rust/p/point_set_range_frequency.rs) |
| V | [`v/p/point_set_range_frequency.v`](../../../v/p/point_set_range_frequency.v) |
| Zig | [`zig/p/point_set_range_frequency.zig`](../../../zig/p/point_set_range_frequency.zig) |
