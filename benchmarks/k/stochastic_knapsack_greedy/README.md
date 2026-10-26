# Stochastic knapsack nonadaptive greedy policy

This profile implements the chapter's explicit nonadaptive approximation for
stochastic knapsack. Each item has a deterministic reward and an independent
finite discrete size distribution. The algorithm compares two policies:

1. Place only the item with largest effective reward
   `w_i = reward_i * Pr[size_i <= capacity]`.
2. Place every item in nonincreasing order of `w_i / μ_i`, where
   `μ_i = E[min(size_i, capacity)]`.

The policy with larger expected reward is returned. Exact integer probability
weights keep all comparisons and expected values rational and deterministic.
Ties for the best singleton go to the smaller item index; ties in the density
order also go to smaller indices; an equal policy score selects the singleton.

Input is `[item_count, capacity, (reward, atom_count, (size, weight)...)...]`.
There are one to five items, capacity is 1 through 8, rewards are 0 through
20, and each item has one to three size atoms. Atom sizes are 0 through
`capacity+1`, positive integer weights are at most 3, and each item's weight
sum is at most 9. At least one atom must have positive truncated size, so
`μ_i > 0` and the source's density rule is defined. The output is the exact
policy as `[kind, item_count, item_indices..., expected_reward_numerator,
probability_denominator]`; `kind=0` denotes the singleton and `kind=1` the
density-ordered policy. The denominator is the product of item probability
weight sums, so the output fraction need not be reduced.

Malformed inputs return `-1`; null output or insufficient capacity returns
`-2` without writing. Maximum valid input is 42 i64 values, 43 values are
accepted for malformed-input checks, maximum output is 72 bytes, and fixed
workspace is bounded at 8192 bytes.

Primary oracle: [`stochastic_knapsack_greedy_oracle.py`](../../stochastic_knapsack_greedy_oracle.py)
enumerates all joint outcomes. The independent verifier
[`stochastic_knapsack_greedy_verifier_oracle.py`](../../stochastic_knapsack_greedy_verifier_oracle.py)
computes the ordered policy reward with a capacity-state dynamic program.

Source: Viswanath Nagarajan, “Stochastic Knapsack,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_537`](https://doi.org/10.1007/978-1-4939-2864-4_537).
This clean-room profile covers the chapter's explicit nonadaptive theorem.
The adaptive-policy theorem is described only by its guarantee and a high-level
reference to a transformation; its algorithmic details are deferred to the
cited paper. See [`RIGHTS.md`](RIGHTS.md) for provenance.

## Workload and ports

The [workload](workload.json) covers both policy choices, exact probability
arithmetic, maximum input/output bounds, malformed distributions, null
buffers, and insufficient capacity.

| Language | Port |
| --- | --- |
| C | [`c/k/stochastic_knapsack_greedy.c`](../../../c/k/stochastic_knapsack_greedy.c) |
| C3 | [`c3/k/stochastic_knapsack_greedy.c3`](../../../c3/k/stochastic_knapsack_greedy.c3) |
| C++ | [`cpp/k/stochastic_knapsack_greedy.cpp`](../../../cpp/k/stochastic_knapsack_greedy.cpp) |
| Elisa | [`elisa/k/stochastic_knapsack_greedy.elisa`](../../../elisa/k/stochastic_knapsack_greedy.elisa) |
| Nim | [`nim/k/stochastic_knapsack_greedy.nim`](../../../nim/k/stochastic_knapsack_greedy.nim) |
| Odin | [`odin/k/stochastic_knapsack_greedy.odin`](../../../odin/k/stochastic_knapsack_greedy.odin) |
| Rust | [`rust/k/stochastic_knapsack_greedy.rs`](../../../rust/k/stochastic_knapsack_greedy.rs) |
| V | [`v/k/stochastic_knapsack_greedy.v`](../../../v/k/stochastic_knapsack_greedy.v) |
| Zig | [`zig/k/stochastic_knapsack_greedy.zig`](../../../zig/k/stochastic_knapsack_greedy.zig) |
