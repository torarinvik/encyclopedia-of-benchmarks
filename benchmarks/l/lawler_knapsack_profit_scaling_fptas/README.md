# Lawler knapsack profit-scaling FPTAS

This bounded 0-1 knapsack profile uses Lawler's lower bound from the fractional
ratio-greedy prefix, separates small and large profits, and scales large-item
profits within dyadic intervals. Large items with equal scaled profit are
grouped, limited to the lightest candidates, and processed as prefix choices
in a dynamic program. A ratio-ordered prefix of small items completes each
large-item state.

## Contract

Input is `[capacity, n, (weight, profit)*n]` with 4..8 items, capacity 1..30,
weights in `1..capacity`, and profits in 32..200. The accuracy is fixed at
`epsilon=1/2`. Restricting `n>=4` and profits to at least 32 keeps the bounded
profile in Lawler's `K>1` branch, where `T=P0/4` and `K=P0/16`.

The scalar packs the actual chosen profit and original-index mask as
`(profit << 8) | mask`. Invalid input returns `-1`. Ties in ratio order use the
input index; final equal-score choices prefer higher actual profit, lower
weight, then lower mask.

Let `Q=32` be the maximum scaled-profit total and `g` the number of nonempty
large-item groups. The ports use insertion sorts, so sorting plus grouped
frontier updates take `O(n^2 + Q(n+g))` time and `O(n+Q)` auxiliary space.
Since `Q` is fixed for `epsilon=1/2`, this bounded profile is `O(n^2)` time
and `O(n)` space.
The independent grouped-subset reference is intentionally exponential in `n`,
which is bounded by eight.

The primary reference uses Lawler's grouped dynamic program. The independent
reference enumerates the allowed prefix choice for each retained equal-q
group instead of maintaining DP states, then applies the same small-item
completion rule. The bounded ports sort ratios and groups directly rather
than using the paper's median-finding optimization; they preserve its dyadic
scaling and equal-q pruning steps.

This is distinct from local
[`knapsack_profit_scaling_fptas`](../../k/knapsack_profit_scaling_fptas/README.md)
and [`knapsack_profit_scaling_small_large_fptas`](../../k/knapsack_profit_scaling_small_large_fptas/README.md).
Those use uniform scaling, while this profile uses a `P0` lower bound,
interval-specific dyadic scales, and equal-q group transitions.

## References

Eugene L. Lawler, “Fast Approximation Algorithms for Knapsack Problems,”
*Mathematics of Operations Research* 4(4), 339–356 (1979),
[DOI 10.1287/moor.4.4.339](https://doi.org/10.1287/moor.4.4.339). The
[Berkeley technical report](https://www2.eecs.berkeley.edu/Pubs/TechRpts/1977/Archive/ERL-m-77-45.pdf)
contains the detailed algorithm sections. Only algorithm ideas are used; no
source code is copied.

## Implementations

| Language | Source |
|---|---|
| C | [c/l/lawler_knapsack_profit_scaling_fptas.c](../../../c/l/lawler_knapsack_profit_scaling_fptas.c) |
| C3 | [c3/l/lawler_knapsack_profit_scaling_fptas.c3](../../../c3/l/lawler_knapsack_profit_scaling_fptas.c3) |
| C++ | [cpp/l/lawler_knapsack_profit_scaling_fptas.cpp](../../../cpp/l/lawler_knapsack_profit_scaling_fptas.cpp) |
| Elisa | [elisa/l/lawler_knapsack_profit_scaling_fptas.elisa](../../../elisa/l/lawler_knapsack_profit_scaling_fptas.elisa) |
| Mojo | [mojo/l/lawler_knapsack_profit_scaling_fptas.mojo](../../../mojo/l/lawler_knapsack_profit_scaling_fptas.mojo) |
| Nim | [nim/l/lawler_knapsack_profit_scaling_fptas.nim](../../../nim/l/lawler_knapsack_profit_scaling_fptas.nim) |
| Odin | [odin/l/lawler_knapsack_profit_scaling_fptas.odin](../../../odin/l/lawler_knapsack_profit_scaling_fptas.odin) |
| Rust | [rust/l/lawler_knapsack_profit_scaling_fptas.rs](../../../rust/l/lawler_knapsack_profit_scaling_fptas.rs) |
| V | [v/l/lawler_knapsack_profit_scaling_fptas.v](../../../v/l/lawler_knapsack_profit_scaling_fptas.v) |
| Zig | [zig/l/lawler_knapsack_profit_scaling_fptas.zig](../../../zig/l/lawler_knapsack_profit_scaling_fptas.zig) |

See [`workload.json`](workload.json) for cases and scalar values.
