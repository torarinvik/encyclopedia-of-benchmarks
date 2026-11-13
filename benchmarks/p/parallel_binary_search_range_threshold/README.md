# Parallel binary search for range-threshold crossing times

This benchmark batches offline searches for the earliest update prefix at
which each inclusive range reaches a requested sum threshold. The primary
method partitions unresolved queries by their midpoint time and replays each
event prefix through two Fenwick trees supporting range addition and range
sum. This is the `i64_array_scalar` profile `parallel_binary_search_range_threshold`.

## Contract

Input is `[N,M,Q,(L,R,delta)*M,(L,R,target)*Q]`. The array length `N` is
1..16; event and query counts `M,Q` are 0..32. Every range is inclusive and
zero-based, with `0<=L<=R<N`. An event adds a nonnegative `delta` in `0..1000`
to every array position in its range. A query asks for the smallest prefix
length `t` in `0..M` whose accumulated sum on its range is at least its
positive threshold `target` in `1..512000`. If no prefix reaches the
threshold, the answer is `M+1`.

The scalar result is `sum((i+1)*(answer_i+1))` in query order, where `i` is
zero-based. Empty query batches return zero. Malformed framing, invalid ranges,
negative or oversized updates, thresholds outside their profile, null input,
and signed values outside the contract return `-1`. Maximum valid and
parseable input lengths are 195 and 196 i64 words. The fixed arrays and
Fenwick state use a declared 4096-byte workspace.

## Method and comparison

All updates are nonnegative, so each query's range sum is monotone in the
event-prefix length. Each parallel-binary-search round groups unresolved
queries by midpoint. Events are replayed once in time order; two Fenwick trees
evaluate range additions and inclusive range sums at the requested midpoints.
The independent oracle handles each query separately, rebuilding the current
array by replaying events and scanning the query range after every prefix.
With these bounds the primary performs at most six rounds, while the direct
oracle remains small and algorithmically independent.

The local [`fenwick_tree`](../../f/fenwick_tree/README.md) package supports
online point addition and range sum, and
[`lazy_segment_tree_range_add_sum`](../../l/lazy_segment_tree_range_add_sum/README.md)
supports online range additions and range sums. This profile measures the
offline batch of first-threshold-time searches over the entire update trace.
It is also distinct from [`range_parallel_unionfind`](../../u/range_parallel_unionfind/README.md),
which uses a time segment tree and rollback DSU to answer connectivity queries.

## Provenance

The clean-room implementation follows the generic offline divide-and-conquer
method described in [OI Wiki — Overall / Parallel Binary Search](https://en.oi-wiki.org/misc/parallel-binsearch/).
OI Wiki states that its default content terms are CC BY-SA 4.0 and SATA; this
repository uses the algorithm description only. No source code, article
prose, examples, or task text was copied. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the primary and independent oracles, and the
static inventory checker.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/parallel_binary_search_range_threshold.c`](../../../c/p/parallel_binary_search_range_threshold.c) |
| C3 | [`c3/p/parallel_binary_search_range_threshold.c3`](../../../c3/p/parallel_binary_search_range_threshold.c3) |
| C++ | [`cpp/p/parallel_binary_search_range_threshold.cpp`](../../../cpp/p/parallel_binary_search_range_threshold.cpp) |
| Elisa | [`elisa/p/parallel_binary_search_range_threshold.elisa`](../../../elisa/p/parallel_binary_search_range_threshold.elisa) |
| Mojo | [`mojo/p/parallel_binary_search_range_threshold.mojo`](../../../mojo/p/parallel_binary_search_range_threshold.mojo) |
| Nim | [`nim/p/parallel_binary_search_range_threshold.nim`](../../../nim/p/parallel_binary_search_range_threshold.nim) |
| Odin | [`odin/p/parallel_binary_search_range_threshold.odin`](../../../odin/p/parallel_binary_search_range_threshold.odin) |
| Rust | [`rust/p/parallel_binary_search_range_threshold.rs`](../../../rust/p/parallel_binary_search_range_threshold.rs) |
| V | [`v/p/parallel_binary_search_range_threshold.v`](../../../v/p/parallel_binary_search_range_threshold.v) |
| Zig | [`zig/p/parallel_binary_search_range_threshold.zig`](../../../zig/p/parallel_binary_search_range_threshold.zig) |
