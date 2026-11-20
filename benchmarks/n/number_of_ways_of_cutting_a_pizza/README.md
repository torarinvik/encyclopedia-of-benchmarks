# Number of ways of cutting a pizza

This bounded profile counts ordered sequences of full horizontal and vertical
guillotine cuts. Every strip given away and the final remaining rectangle must
contain at least one apple. The answer is returned modulo 1,000,000,007.

## Contract

- ABI: `i64_array_scalar`; symbol: `number_of_ways_of_cutting_a_pizza`.
- Input: `[rows, columns, cuts, cell_0, ...]`, with row-major binary cells.
- `rows` and `columns` are each in `1..=6`; `cuts` is in `0..=5`.
- The exact input length is `3 + rows*columns`, at most 39 i64 words.
- A valid zero-cut instance returns 1 exactly when the whole pizza has an
  apple; otherwise it returns 0. Malformed or out-of-profile input returns
  `-1`.

## Method and references

The primary builds a two-dimensional suffix apple-count table. Its DP state
`dp[r][c][q]` counts ways to make exactly `q` further cuts from the remaining
rectangle whose upper-left corner is `(r,c)` and whose lower-right corner is
fixed at the pizza boundary. For each horizontal or vertical cut, it adds the
state for the remaining lower or right rectangle only if the strip given away
contains an apple. The zero-cut base case tests whether the final rectangle
contains an apple. This takes `O(cuts*rows*columns*(rows+columns))` time and
`O(rows*columns)` auxiliary space.

The independent reference recursively tries legal first cuts and counts
apples by scanning each proposed strip directly. It does not use a suffix
table. It serves as a separate bounded recurrence with direct region scans.

This is distinct from [`broken_profile_domino_tilings`](../../b/broken_profile_domino_tilings/README.md),
which counts frontier-compatible tile placements, and from
[`table_compression_optimal_contiguous_partition`](../../t/table_compression_optimal_contiguous_partition/README.md),
which chooses a one-dimensional partition under a compression-cost function.

The algorithm source is the official [LeetCode 1444 problem and hints](https://leetcode.com/problems/number-of-ways-of-cutting-a-pizza/).
Its hints specify the fixed lower-right corner, `(top,left,cuts_remaining)`
state, legal apple-containing strips, and a 2D table for constant-time apple
queries. This package uses those algorithm hints only; the bounded ABI,
fixtures, references, prose, and ports are independently written. No problem
statement text, examples, code, tests, or editorial text was copied. See
[`RIGHTS.md`](RIGHTS.md).

## Workload and inventory

[`workload.json`](workload.json) includes zero cuts, no apples, one-row and
one-column cuts, one-cut and multi-cut cases, the maximum valid frame, a
maximum-length malformed frame, and domain/framing errors. The package-local
static inventory checker is [`check_inventory.py`](check_inventory.py); it
checks files and source references without running the workload.

| Language | Source |
|---|---|
| C | [`c/n/number_of_ways_of_cutting_a_pizza.c`](../../../c/n/number_of_ways_of_cutting_a_pizza.c) |
| C3 | [`c3/n/number_of_ways_of_cutting_a_pizza.c3`](../../../c3/n/number_of_ways_of_cutting_a_pizza.c3) |
| C++ | [`cpp/n/number_of_ways_of_cutting_a_pizza.cpp`](../../../cpp/n/number_of_ways_of_cutting_a_pizza.cpp) |
| Elisa | [`elisa/n/number_of_ways_of_cutting_a_pizza.elisa`](../../../elisa/n/number_of_ways_of_cutting_a_pizza.elisa) |
| Mojo | [`mojo/n/number_of_ways_of_cutting_a_pizza.mojo`](../../../mojo/n/number_of_ways_of_cutting_a_pizza.mojo) |
| Nim | [`nim/n/number_of_ways_of_cutting_a_pizza.nim`](../../../nim/n/number_of_ways_of_cutting_a_pizza.nim) |
| Odin | [`odin/n/number_of_ways_of_cutting_a_pizza.odin`](../../../odin/n/number_of_ways_of_cutting_a_pizza.odin) |
| Rust | [`rust/n/number_of_ways_of_cutting_a_pizza.rs`](../../../rust/n/number_of_ways_of_cutting_a_pizza.rs) |
| V | [`v/n/number_of_ways_of_cutting_a_pizza.v`](../../../v/n/number_of_ways_of_cutting_a_pizza.v) |
| Zig | [`zig/n/number_of_ways_of_cutting_a_pizza.zig`](../../../zig/n/number_of_ways_of_cutting_a_pizza.zig) |
