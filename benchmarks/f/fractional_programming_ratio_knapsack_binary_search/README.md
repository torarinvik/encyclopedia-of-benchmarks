# Fractional programming by ratio bisection and knapsack

This benchmark selects any nonempty subset of items whose total denominator
reaches a required threshold, maximizing the ratio of total numerator to total
denominator. It returns the optimum multiplied by one million and floored to
an integer.

## Contract

- ABI: `i64_array_scalar`; input is `[n,W,(a_i,b_i)*n]`.
- Accept `1<=n<=12`, `1<=W<=32`, `0<=a_i<=1000`, and `1<=b_i<=8`, with
  `W<=sum(b_i)`. The maximum valid frame is 26 i64 words; one trailing-word
  probe is 27 words.
- Return `floor(1,000,000 * max(sum(a_i)/sum(b_i)))` over subsets whose
  denominator sum is at least `W`. The output range is `0..=1,000,000,000`.
- Malformed, null, or out-of-domain input returns `-1`.
- The fixed workspace allowance is 2,048 bytes, covering two 33-entry i64 DP
  rows, the bounded item arrays, and scalar bookkeeping.

## Algorithm and distinction

For a candidate scaled ratio `q`, the inequality
`sum(a_i)/sum(b_i) >= q/1,000,000` is equivalent to
`sum(1,000,000*a_i-q*b_i) >= 0`. The primary binary-searches the largest
integer `q` for which a subset satisfying the denominator threshold has a
nonnegative transformed sum. A two-row 0/1 knapsack DP stores the best
transformed sum for each denominator total, capping totals at `W`. The two rows
ensure each item is included at most once. The time is
`O(n*W*log(1,000,000,001))` and auxiliary space is `O(W)`.

The independent reference enumerates every nonempty subset and compares its
exact rational ratio using integer cross-products before scaling and flooring.
It does not use threshold bisection or knapsack DP.

The local [`dinkelbach_fixed_cardinality_ratio`](../dinkelbach_fixed_cardinality_ratio/README.md)
benchmark requires exactly `K` selected items and iteratively applies
Dinkelbach updates with a top-`K` residual selector. This package uses a
minimum-denominator constraint, knapsack feasibility, and binary search, so
it measures a distinct fractional-programming method.

## Provenance and rights

The method description follows [OI Wiki's Fractional Programming article](https://oi-wiki.org/misc/frac-programming/),
which discusses ratio bisection and transforming the candidate ratio into an
additive objective; its minimum-denominator example uses 0/1 knapsack. OI Wiki
states CC BY-SA 4.0 and SATA terms. Only algorithm ideas are used: no source
code, prose, examples, or tests are copied. The local contract, references,
ports, and fixtures are independently authored. See [`RIGHTS.md`](RIGHTS.md).

The [workload](workload.json), [primary reference](primary_oracle.py),
[independent reference](independent_oracle.py),
[fixture checker source](verify_workload.py), and
[static inventory checker source](check_inventory.py) are package-local.
The scalar runner/verifier and root catalog integration are complete.
No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks have been run.

## Implementations

| Language | Source |
|---|---|
| C | [`c/f/fractional_programming_ratio_knapsack_binary_search.c`](../../../c/f/fractional_programming_ratio_knapsack_binary_search.c) |
| C3 | [`c3/f/fractional_programming_ratio_knapsack_binary_search.c3`](../../../c3/f/fractional_programming_ratio_knapsack_binary_search.c3) |
| C++ | [`cpp/f/fractional_programming_ratio_knapsack_binary_search.cpp`](../../../cpp/f/fractional_programming_ratio_knapsack_binary_search.cpp) |
| Elisa | [`elisa/f/fractional_programming_ratio_knapsack_binary_search.elisa`](../../../elisa/f/fractional_programming_ratio_knapsack_binary_search.elisa) |
| Mojo | [`mojo/f/fractional_programming_ratio_knapsack_binary_search.mojo`](../../../mojo/f/fractional_programming_ratio_knapsack_binary_search.mojo) |
| Nim | [`nim/f/fractional_programming_ratio_knapsack_binary_search.nim`](../../../nim/f/fractional_programming_ratio_knapsack_binary_search.nim) |
| Odin | [`odin/f/fractional_programming_ratio_knapsack_binary_search.odin`](../../../odin/f/fractional_programming_ratio_knapsack_binary_search.odin) |
| Rust | [`rust/f/fractional_programming_ratio_knapsack_binary_search.rs`](../../../rust/f/fractional_programming_ratio_knapsack_binary_search.rs) |
| V | [`v/f/fractional_programming_ratio_knapsack_binary_search.v`](../../../v/f/fractional_programming_ratio_knapsack_binary_search.v) |
| Zig | [`zig/f/fractional_programming_ratio_knapsack_binary_search.zig`](../../../zig/f/fractional_programming_ratio_knapsack_binary_search.zig) |
