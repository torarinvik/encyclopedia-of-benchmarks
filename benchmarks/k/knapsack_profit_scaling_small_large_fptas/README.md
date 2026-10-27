# Knapsack profit-scaling FPTAS with small-item fill

This profile implements the chapter's Ibarra–Kim small/large-item improvement
to profit scaling (DOI `10.1007/978-1-4939-2864-4_192`). It is a separate
algorithm from the base DP-Profits FPTAS in
[`knapsack_profit_scaling_fptas`](../knapsack_profit_scaling_fptas/README.md).

## Contract

- Input is `[capacity, n, weight_0, profit_0, ...]`, with capacity 1–30,
  `n` 1–8, and weights/profits 1–30 / 1–100. The exact frame length is `2+2n`
  (at most 18 signed 64-bit words).
- Fix `epsilon=1/2`. Compute the exact rational fractional-knapsack upper
  bound `U_LP` by descending exact profit/weight ratio, with item ID breaking
  ratio ties. Retain the fractional part of the last fitting item exactly;
  items heavier than the capacity are ineligible.
- An eligible item is small when `p_i <= epsilon*U_LP/2` (equivalently
  `4*p_i <= U_LP`); otherwise it is large. Sort small items by descending
  exact profit/weight ratio, then ID. The large-item DP uses scaled profits
  `floor(16*p_i/U_LP)`, corresponding to `K=epsilon^2*U_LP/4` at this fixed
  epsilon. It retains minimum weight per scaled-profit total; equal weights
  retain the numerically smaller item mask.
- Since each eligible item satisfies `p_i <= U_LP`, every scaled profit is at
  most 16 and the DP has at most `16*n <= 128` total-profit states.
- For every reachable large-item DP state, scan the small items in that order
  and add each item that fits the residual capacity, continuing past items
  that do not fit. Select the candidate with greatest original total profit;
  equal profits choose the numerically smaller mask. Output is two little-endian
  signed 64-bit integers `[mask, original_profit]` (16 bytes).
- Invalid frames/values and null input return `-1`; null output or capacity
  below 16 returns `-2`. Validation precedes output checks and errors write no
  output bytes.

This is a bounded deterministic refinement of the chapter procedure. The tie
rules and continue-after-nonfitting-item behavior make otherwise unspecified
choices stable; the profile does not claim a guarantee for a different epsilon
or reproduce later Lawler/Magazine–Oguz/Kellerer–Pferschy schemes.

## Source and rights

The source is the supplied *Encyclopedia of Algorithms*, “Knapsack,” DOI
`10.1007/978-1-4939-2864-4_192`, which summarizes Ibarra and Kim. The ports are
clean-room implementations; no book prose, figures, or upstream code is
reproduced. See [RIGHTS.md](RIGHTS.md).

The primary oracle uses scaled-profit dynamic programming. The independent
verifier enumerates all bounded large-item subsets and independently recovers
the minimum-weight state for each scaled total before applying the greedy
small-item fill.

## Ports

C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig export
`knapsack_profit_scaling_small_large_fptas` via `i64_array_bytes_output`.
