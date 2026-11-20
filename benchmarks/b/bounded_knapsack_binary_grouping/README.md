# Bounded knapsack by binary grouping

This profile maximizes value subject to a capacity limit when each item type
has a finite multiplicity. Its primary kernel decomposes each count into
power-of-two bundles plus a final remainder, then processes each bundle as a
0/1 item.

## Contract

The `i64_array_scalar` input is `[n,capacity,(weight,value,count)*n]`.
There are `0..16` item types, `0<=capacity<=64`, weights are `1..16`, values
are `0..100`, and counts are `0..16`. Both zero count and zero value are
valid. The frame must contain exactly `2+3*n` signed 64-bit values; up to 51
words are parseable so trailing data can be rejected. The maximum valid and
parseable lengths are 50 and 51 words. The result is the maximum total value
using at most the supplied capacity. An empty selection is allowed, so valid
results are nonnegative; malformed or out-of-profile input returns `-1`.

For each count `k`, the primary emits bundles of sizes `1,2,4,...` and one
remaining bundle when needed. These bundles can represent every number of
copies from zero through `k`. Each bundle has
weight and value multiplied by its copy count and is applied with a descending
capacity loop, ensuring it is used at most once. With capacity `C`, `n` types,
and `k_i` copies of type `i`, the work is
`O(C * sum(log(k_i+1)))`; the DP uses `O(C)` auxiliary space.

The independent oracle does not form bundles. It enumerates the copy count
for each type directly in a new capacity-DP row, taking
`O(C * sum(k_i+1))` time and `O(C)` space.

This is distinct from [`bounded_knapsack_monotone_queue`](../bounded_knapsack_monotone_queue/README.md),
which uses residue-class sliding maxima for the same operation. Binary
grouping performs a sequence of 0/1 bundle updates and requires no deque or
residue partition.

## Source and files

Primary source: [CP-Algorithms, “Knapsack Problem,” Binary Grouping Optimization](https://cp-algorithms.com/dynamic_programming/knapsack.html#binary-grouping-optimization).
The source is used for algorithm discovery and description only; the package
is clean-room. See [`RIGHTS.md`](RIGHTS.md).

The hand-derived cases are in [`workload.json`](workload.json). The primary
reference is [`primary_oracle.py`](primary_oracle.py); the independent
copy-count DP is [`independent_oracle.py`](independent_oracle.py). Static
package/workload preflights are [`verify_workload.py`](verify_workload.py) and
[`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/bounded_knapsack_binary_grouping.c`](../../../c/b/bounded_knapsack_binary_grouping.c) |
| C3 | [`c3/b/bounded_knapsack_binary_grouping.c3`](../../../c3/b/bounded_knapsack_binary_grouping.c3) |
| C++ | [`cpp/b/bounded_knapsack_binary_grouping.cpp`](../../../cpp/b/bounded_knapsack_binary_grouping.cpp) |
| Elisa | [`elisa/b/bounded_knapsack_binary_grouping.elisa`](../../../elisa/b/bounded_knapsack_binary_grouping.elisa) |
| Mojo | [`mojo/b/bounded_knapsack_binary_grouping.mojo`](../../../mojo/b/bounded_knapsack_binary_grouping.mojo) |
| Nim | [`nim/b/bounded_knapsack_binary_grouping.nim`](../../../nim/b/bounded_knapsack_binary_grouping.nim) |
| Odin | [`odin/b/bounded_knapsack_binary_grouping.odin`](../../../odin/b/bounded_knapsack_binary_grouping.odin) |
| Rust | [`rust/b/bounded_knapsack_binary_grouping.rs`](../../../rust/b/bounded_knapsack_binary_grouping.rs) |
| V | [`v/b/bounded_knapsack_binary_grouping.v`](../../../v/b/bounded_knapsack_binary_grouping.v) |
| Zig | [`zig/b/bounded_knapsack_binary_grouping.zig`](../../../zig/b/bounded_knapsack_binary_grouping.zig) |

No programs, tests, scripts, checkers, builds, compilers, benchmarks, or
profilers were run while preparing this package.
