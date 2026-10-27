# Greedy rumor blocking with supplied live-edge worlds

This profile implements the chapter's greedy protector-selection rule for
Problem 1 under the Multi-Campaign Independent Cascade Model's high-effectiveness
condition. The profile fixes protector edge success to 1 and detection delay to
`d=0`. Rumor-edge outcomes are supplied as a finite set of live-edge worlds,
which is the deterministic input form of the chapter's Monte Carlo estimate.

For each world, the runner computes the no-protector baseline and the number
of baseline-infected nodes prevented by the current protector set. At every
greedy round, it evaluates each unselected, non-rumor-source vertex using the
same worlds and chooses the greatest sum of marginal prevented-node counts.
Equal scores choose the lower vertex ID. Propagation is synchronous. Rumor
activations use each edge's live bit for that world; protector activations
always succeed, and a protector proposal wins when rumor and protector both
target the same inactive vertex in one step. Activated statuses persist.

Input is signed i64 words:

```text
[n,m,rumor_source_count,k,world_count, rumor_sources...,
 (edge_source,edge_target,live_world_mask)...]
```

There are 2–8 vertices, at most 16 distinct directed non-self edges, 1 to
`n-1` rumor sources, `1<=k<=min(3,n-|R|)`, and 1–8 worlds. The maximum valid
input is 60 words (the parser accepts up to 61 words to classify malformed
framing). Bit `w` of an
edge's mask says whether rumor transmission along that edge succeeds in world
`w`. The sampled outcomes are held fixed across the baseline, current-set,
and candidate-set simulations, so marginal estimates use common random
numbers. This is a finite supplied-sample greedy trace; it does not generate
random worlds or claim a stochastic approximation guarantee.

Output is little-endian signed i64:

```text
[k, selected_node_0, marginal_sum_0, ..., selected_node_(k-1), marginal_sum_(k-1)]
```

Each marginal sum is the total over all supplied worlds; divide by
`world_count` for the empirical mean. Input is bounded to 60 valid words, output to
56 bytes, and fixed workspace to 4096 bytes. Invalid input returns `-1`; null
output or insufficient capacity returns `-2` without writing.

The bounded contract preserves the chapter's greedy set-function procedure
and synchronous high-effectiveness MCICM competition, with deterministic
supplied simulation worlds and an explicit tie rule. COICM, `d>0`, stochastic
world generation, and edge/node blocking (Problem 2) are not included.

Source: Lidan Fan and Weili Wu, “Rumor Blocking,” Encyclopedia of Algorithms,
DOI `10.1007/978-1-4939-2864-4_623`, `OEBPS/AChap623.html`, Problem 1,
MCICM, high-effectiveness property, and Algorithm 1. The chapter provides no
source-code license grant; these ports are clean-room implementations.

Primary and independent verifier oracles:
`benchmarks/rumor_blocking_greedy_live_edge_oracle.py` and
`benchmarks/rumor_blocking_greedy_live_edge_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/s/rumor_blocking_greedy_live_edge.c` |
| C3 | `c3/s/rumor_blocking_greedy_live_edge.c3` |
| C++ | `cpp/s/rumor_blocking_greedy_live_edge.cpp` |
| Elisa | `elisa/s/rumor_blocking_greedy_live_edge.elisa` |
| Nim | `nim/s/rumor_blocking_greedy_live_edge.nim` |
| Odin | `odin/s/rumor_blocking_greedy_live_edge.odin` |
| Rust | `rust/s/rumor_blocking_greedy_live_edge.rs` |
| V | `v/s/rumor_blocking_greedy_live_edge.v` |
| Zig | `zig/s/rumor_blocking_greedy_live_edge.zig` |
