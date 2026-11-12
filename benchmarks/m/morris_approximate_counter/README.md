# Morris Approximate Counter

This benchmark implements the original base-2 Morris counter. It follows
Robert Morris's *Counting Large Numbers of Events in Small Registers*
([DOI](https://doi.org/10.1145/359619.359627)) and the base-2 derivation in
the [Algorithm Archive](https://www.algorithm-archive.org/contents/approximate_counting/approximate_counting.html).
The sources are used for the algorithm description only; every port and the
oracle are clean-room implementations.

## Contract

Input is `[Q, draw_0, ..., draw_(Q-1)]`, with `1 <= Q <= 53`. Each draw is an
integer in `[0, 2^53)`. The draw tape represents exact discrete uniform
variates `draw / 2^53` in `[0, 1)`. Start with compressed state `v = 0`. For
each event, increment `v` when `draw < 2^(53-v)`, which gives the Morris
transition probability `2^-v` for every reachable state in this bound.

Return two little-endian signed 64-bit integers: the final compressed state
and its decoded estimate `2^v - 1`. With at most 53 updates, the maximum state
is 53 and the maximum estimate is `9,007,199,254,740,991`, which fits in a
signed 64-bit value. Invalid input returns `-1`; null output or capacity below
16 bytes returns `-2`, without writing output.

The supplied tape makes each call reproducible. The tape alone carries no
probability distribution claim, so the benchmark makes no deterministic
approximation-error guarantee. If draws are sampled independently and
uniformly, the state transition is the standard Morris counter.

## Algorithm and bounds

The counter stores only the compressed exponent `v`. For state zero, every
draw passes the `2^53` threshold and the first event is always counted. At
state `v`, the next increment is accepted for exactly `2^(53-v)` of the
`2^53` possible draw values. The decoded estimate is `2^v - 1`. Each call
uses `O(Q)` time and `O(1)` state. The maximum input has 54 integers and the
output is 16 bytes.

The Python oracle replays integer tape thresholds and emits the two output
integers. See [`workload.json`](workload.json) for deterministic tapes,
boundary cases, and invalid-input cases.

## Distinction from existing benchmarks

The repository has exact counters and Morris inorder tree traversal, but no
stochastic approximate counter. The Morris traversal temporarily threads tree
nodes and does not maintain a probabilistic count; this benchmark has a
different state transition, input tape, and estimate output.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/morris_approximate_counter.c`](../../../c/m/morris_approximate_counter.c) |
| C3 | [`c3/m/morris_approximate_counter.c3`](../../../c3/m/morris_approximate_counter.c3) |
| C++ | [`cpp/m/morris_approximate_counter.cpp`](../../../cpp/m/morris_approximate_counter.cpp) |
| Elisa | [`elisa/m/morris_approximate_counter.elisa`](../../../elisa/m/morris_approximate_counter.elisa) |
| Mojo | [`mojo/m/morris_approximate_counter.mojo`](../../../mojo/m/morris_approximate_counter.mojo) |
| Nim | [`nim/m/morris_approximate_counter.nim`](../../../nim/m/morris_approximate_counter.nim) |
| Odin | [`odin/m/morris_approximate_counter.odin`](../../../odin/m/morris_approximate_counter.odin) |
| Rust | [`rust/m/morris_approximate_counter.rs`](../../../rust/m/morris_approximate_counter.rs) |
| V | [`v/morris_approximate_counter.v`](../../../v/morris_approximate_counter.v) |
| Zig | [`zig/m/morris_approximate_counter.zig`](../../../zig/m/morris_approximate_counter.zig) |
