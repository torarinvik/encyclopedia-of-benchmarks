# Greedy influence maximization over supplied live-edge worlds

This package profiles the InfMax greedy procedure in Chapter 624, Algorithm 1.
Starting with an empty seed set, each round chooses the unselected vertex with
the largest marginal increase in expected active vertices. The chapter defines
the independent-cascade (IC) model and says to estimate influence with Monte
Carlo simulation. This bounded profile supplies the sampled cascade worlds as
directed live-edge masks, making each call deterministic.

Input is a signed-i64 array:

```text
[n, m, k, world_count, (u, v, live_world_mask) * m]
```

The profile allows `1<=n<=8`, `0<=m<=24`, `0<=k<=n`, and `1<=world_count<=8`.
Each directed arc has distinct endpoints, and duplicate ordered arcs are
rejected. Bit `w` of an arc mask says that the arc transmits in supplied world
`w`; worlds are equally weighted. The maximum valid input is 76 words. The
parser accepts up to 77 words to classify a single trailing word as invalid.
The maximum mask is `(1<<world_count)-1`.

For seed set `S`, the sampled influence is the mean number of vertices
reachable from `S` in the supplied live-edge graphs. At each of `k` rounds,
the implementation chooses the unselected vertex with the largest sum, over
worlds, of newly reachable vertices. Comparing these sums is equivalent to
comparing mean marginal influence because every candidate uses the same number
of worlds. Equal sums choose the smallest vertex ID. The selected seed and
its marginal sum are recorded after each round.

Output is little-endian signed i64 words:

```text
[k, selected_node_0, marginal_sum_0, ..., selected_node_(k-1), marginal_sum_(k-1)]
```

For `k=0`, output is `[0]`. The maximum output is 136 bytes, and fixed workspace
is 4096 bytes. Invalid input returns `-1`. Null output or insufficient capacity
returns `-2` and writes no bytes. The C ABI ports accept the input and output
buffers only at the exported function boundary.

The primary reference traverses each world from the selected seeds with a
queue. The independent reference computes each world's transitive closure and
counts the union of seed-reachable vertices. Both independently replay the
greedy trace and serialize its selected IDs and marginal sums. Workload fixtures
cover zero-budget behavior, tie order, directed propagation, multiple sample
worlds, diminishing marginal gains, the maximum frame/output, malformed arcs
and masks, null input/output, and insufficient capacity.

The supplied worlds define a deterministic empirical objective. This profile
does not generate random cascades or claim a probabilistic approximation
guarantee for the true diffusion expectation. It differs from
[`rumor_blocking_greedy_live_edge`](../s/rumor_blocking_greedy_live_edge/README.md),
which chooses protectors to limit a competing rumor cascade under MCICM; this
profile chooses initial seeds to maximize one IC cascade's active-set size.

Source: Fan and Wu, “Influence and Profit,” *Encyclopedia of Algorithms*,
[Chapter 624](https://doi.org/10.1007/978-1-4939-2864-4_624), IC model, InfMax
Problem 1, and Algorithm 1. The chapter points to Kempe, Kleinberg, and Tardos,
[“Maximizing the Spread of Influence Through a Social Network”](https://doi.org/10.1145/956750.956769).
Algorithm ideas only; clean-room implementation.

## Ports

| Language | Source |
|---|---|
| C | `c/i/influence_maximization_greedy_live_edge.c` |
| C3 | `c3/i/influence_maximization_greedy_live_edge.c3` |
| C++ | `cpp/i/influence_maximization_greedy_live_edge.cpp` |
| Elisa | `elisa/i/influence_maximization_greedy_live_edge.elisa` |
| Mojo | `mojo/i/influence_maximization_greedy_live_edge.mojo` |
| Nim | `nim/i/influence_maximization_greedy_live_edge.nim` |
| Odin | `odin/i/influence_maximization_greedy_live_edge.odin` |
| Rust | `rust/i/influence_maximization_greedy_live_edge.rs` |
| V | `v/i/influence_maximization_greedy_live_edge.v` |
| Zig | `zig/i/influence_maximization_greedy_live_edge.zig` |

Primary and independent references are in `primary_oracle.py` and
`independent_oracle.py`. `check_inventory.py` performs static source and
metadata checks; it was not run for this source-only change.
