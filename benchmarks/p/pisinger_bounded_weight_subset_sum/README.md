# Pisinger bounded-weight subset sum

This profile returns the largest subset sum that does not exceed a target.
Every supplied weight is a distinct 0/1 item, even when multiple weights have
the same value. It uses Pisinger's balanced-state method from the subset-sum
section of “Linear Time Algorithms for Knapsack Problems with Bounded Weights,”
not the usual capacity-indexed Boolean table.

## Contract

The `i64_array_scalar` input is `[n,target,weight_0,...,weight_(n-1)]`.
There are `0..32` items, `target` is `0..256`, and every positive weight is
`1..12`. Length must equal `n+2`; up to 35 words can be parsed so malformed
trailing data can be rejected. The result is the greatest attainable subset
sum no larger than `target`; the empty subset makes zero a valid result for an
empty item list or a zero target. Null input, malformed framing, or any value
outside the profile returns `-1`. Maximum valid and parseable input lengths
are 34 and 35 i64 words.

## Method

Let `W` be the largest item weight. Greedily include the input prefix while it
fits; the first excluded item is the break item. The primary keeps `2W` states
for masses in `[target-W+1,target+W]`, indexed by
`mass + W - target - 1`, and stores the largest item boundary that can reach
each mass (`-1` means unreachable). For each later item it copies the
previous state, inserts the item into lower-side masses, then scans
over-capacity states downward and removes earlier items between the old and new
boundaries. The descending scan permits repeated removals while preserving the
boundary invariant. The greedy break prefix lies within `W-1` of the target,
so the optimum is represented in this bounded window. This is the BALSUB
state update used by Pisinger's bounded-weight method, specialized to subset
sum where each item's profit equals its weight.

With `n<=32` and `W<=12`, the recurrence takes `O(nW)` time using two rolling
arrays of `2W` boundary states. The independent reference uses ordinary
descending capacity reachability in `O(n*target)` time. It checks the same
result without the break solution, balancing theorem, or boundary-state update.

The closest local profiles are [`subset_sum_nonnegative_exists`](../../s/subset_sum_nonnegative_exists/README.md),
which returns exact-target reachability using capacity DP,
[`minimum_sum_partition`](../../m/minimum_sum_partition/README.md), which
minimizes a two-way partition difference using a subset-sum table, and
[`knapsack_zero_one_tabulation`](../../k/knapsack_zero_one_tabulation/README.md),
which optimizes values under a capacity. They do not implement Pisinger's
balanced-state kernel, so this package adds an algorithmically distinct
bounded-weight profile.

## Sources and provenance

The primary algorithm description is David Pisinger, [“Linear Time Algorithms
for Knapsack Problems with Bounded Weights,” *Journal of Algorithms* 33(1),
1999](https://doi.org/10.1006/jagm.1999.1034), Section 3. KACTL's [`FastKnapsack.h`](https://github.com/kth-competitive-programming/kactl/blob/main/content/various/FastKnapsack.h)
provides a short subset-sum application and cites Pisinger's paper. The
implementations here are clean-room translations of the mathematical
procedure; no upstream code, test data, or prose is copied. See
[`RIGHTS.md`](RIGHTS.md) and [`INVENTORY.md`](INVENTORY.md).

The hand-derived fixtures are in [`workload.json`](workload.json). The primary
reference is [`primary_oracle.py`](primary_oracle.py); the independent
capacity-DP reference is [`independent_oracle.py`](independent_oracle.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/pisinger_bounded_weight_subset_sum.c`](../../../c/p/pisinger_bounded_weight_subset_sum.c) |
| C3 | [`c3/p/pisinger_bounded_weight_subset_sum.c3`](../../../c3/p/pisinger_bounded_weight_subset_sum.c3) |
| C++ | [`cpp/p/pisinger_bounded_weight_subset_sum.cpp`](../../../cpp/p/pisinger_bounded_weight_subset_sum.cpp) |
| Elisa | [`elisa/p/pisinger_bounded_weight_subset_sum.elisa`](../../../elisa/p/pisinger_bounded_weight_subset_sum.elisa) |
| Mojo | [`mojo/p/pisinger_bounded_weight_subset_sum.mojo`](../../../mojo/p/pisinger_bounded_weight_subset_sum.mojo) |
| Nim | [`nim/p/pisinger_bounded_weight_subset_sum.nim`](../../../nim/p/pisinger_bounded_weight_subset_sum.nim) |
| Odin | [`odin/p/pisinger_bounded_weight_subset_sum.odin`](../../../odin/p/pisinger_bounded_weight_subset_sum.odin) |
| Rust | [`rust/p/pisinger_bounded_weight_subset_sum.rs`](../../../rust/p/pisinger_bounded_weight_subset_sum.rs) |
| V | [`v/p/pisinger_bounded_weight_subset_sum.v`](../../../v/p/pisinger_bounded_weight_subset_sum.v) |
| Zig | [`zig/p/pisinger_bounded_weight_subset_sum.zig`](../../../zig/p/pisinger_bounded_weight_subset_sum.zig) |

No programs, tests, scripts, checkers, builds, compilers, benchmarks, or
profilers were run while preparing this package.
