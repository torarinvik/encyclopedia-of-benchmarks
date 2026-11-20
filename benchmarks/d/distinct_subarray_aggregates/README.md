# Distinct subarray aggregates

This bounded benchmark compresses suffixes by equal aggregate values. For each
new array value, it extends every previous suffix aggregate and merges adjacent
start-index ranges that now have the same result. One mode selects GCD, bitwise
OR, or bitwise AND; these exercise the same compression algorithm with
different idempotent operations and are kept in one benchmark package.

## Contract

The scalar symbol is `distinct_subarray_aggregates(input, length) -> i64`.
Input is `[mode,N,values...]`, with `0<=N<=64` and each value in `0..255`.
Mode `0` uses nonnegative integer GCD, mode `1` uses bitwise OR, and mode `2`
uses bitwise AND. An empty array returns zero. Invalid mode, value, null input,
or malformed framing returns `-1`.

The result packs two statistics as
`1024 * aggregate_sum + suffix_distinct_count`. `aggregate_sum` is the sum of
the selected operation over all nonempty subarrays. `suffix_distinct_count`
sums, for each right endpoint, the number of distinct aggregate values among
subarrays ending there. The independent reference visits every subarray
directly and counts each endpoint's values with a set.

For one endpoint, OR and AND can change at most eight times as the start moves,
because each strict change adds or removes at least one of the eight bits.
GCD has at most one zero value followed by a strictly decreasing positive
divisor chain, with each strict drop at least halving the value. Thus at most
nine distinct suffix aggregates occur per endpoint, so the secondary count is
at most `9*64=576`. The multiplier `1024` exceeds this bound. The aggregate sum
is at most `255 * 64*65/2 = 530400`; the packed result fits in signed 64-bit.

## Algorithm and distinction

The primary keeps `(aggregate,left,right)` ranges sorted by `left`. On a push,
it combines each old aggregate with the new value, appends the singleton suffix,
and merges neighboring ranges with equal aggregate values. This takes
`O(N*S)` total work for `S<=9` ranges per endpoint. The independent oracle
folds all `O(N^2)` subarrays directly, without maintaining range summaries.

This is distinct from [`prefix_aggregate_list`](../../p/prefix_aggregate_list/README.md),
which emits whole-array prefix folds, [`subarray_sum_equals_k`](../../s/subarray_sum_equals_k/README.md),
which counts target-sum intervals, and [`count_distinct_elements_in_window`](../../c/count_distinct_elements_in_window/README.md),
which tracks element uniqueness in fixed-width windows. None groups all suffixes
at each right endpoint by an idempotent aggregate. The three modes are not
separate algorithm variants.

The source idea is from Algovault's pinned
[`distinct_subarray_aggregates.cpp`](https://github.com/sgtlaugh/algovault/blob/78cdaf62b70ca0622e8887d2e357fb90b91d449c/code_library/data_structures/distinct_subarray_aggregates.cpp).
See [`RIGHTS.md`](RIGHTS.md) for provenance.

## Language ports

| Language | Source |
|---|---|
| C | [`c/d/distinct_subarray_aggregates.c`](../../../c/d/distinct_subarray_aggregates.c) |
| C3 | [`c3/d/distinct_subarray_aggregates.c3`](../../../c3/d/distinct_subarray_aggregates.c3) |
| C++ | [`cpp/d/distinct_subarray_aggregates.cpp`](../../../cpp/d/distinct_subarray_aggregates.cpp) |
| Elisa | [`elisa/d/distinct_subarray_aggregates.elisa`](../../../elisa/d/distinct_subarray_aggregates.elisa) |
| Mojo | [`mojo/d/distinct_subarray_aggregates.mojo`](../../../mojo/d/distinct_subarray_aggregates.mojo) |
| Nim | [`nim/d/distinct_subarray_aggregates.nim`](../../../nim/d/distinct_subarray_aggregates.nim) |
| Odin | [`odin/d/distinct_subarray_aggregates.odin`](../../../odin/d/distinct_subarray_aggregates.odin) |
| Rust | [`rust/d/distinct_subarray_aggregates.rs`](../../../rust/d/distinct_subarray_aggregates.rs) |
| V | [`v/d/distinct_subarray_aggregates.v`](../../../v/d/distinct_subarray_aggregates.v) |
| Zig | [`zig/d/distinct_subarray_aggregates.zig`](../../../zig/d/distinct_subarray_aggregates.zig) |

The package is registered with the `i64_array_scalar` runner and verifier.
