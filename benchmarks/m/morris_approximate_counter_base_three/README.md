# Morris approximate counter with base-three transition scale

This is a parameter variant of the existing [`morris_approximate_counter`](../morris_approximate_counter/README.md), not a different counter family. It follows the tunable-parameter section of the [Algorithm Archive Approximate Counting chapter](https://www.algorithm-archive.org/contents/approximate_counting/approximate_counting.html), fixing its parameter to `a=1/2`.

## Contract

The `i64_array_bytes_output` entry point is `morris_approximate_counter_base_three`. Input is `[Q, draw_0, ..., draw_(Q-1)]`, where `0<=Q<=30` and each signed i64 draw is in `[0,3^30)`. A zero-event tape is valid. The input length must be exactly `1+Q`; 32 words are parseable for the one-extra-word rejection case.

Start at compressed state `v=0`. For each supplied draw, increment the state iff `draw < 3^(30-v)`. Emit two little-endian signed i64 values: the final state and `(3^v-1)/2`. The maximum state is 30 and the maximum estimate is `102,945,566,047,324`.

Malformed framing, out-of-range words, and null input return `-1`. After validating the entire input, a null output pointer or capacity below 16 bytes returns `-2` without writing. Success returns 16. Workspace is 32 bytes.

The supplied tape fixes a deterministic trace. This benchmark makes no claim that the tape has a probability distribution or that an individual estimate has a particular accuracy.

## Method and distinction

The generalized Morris estimate is `n_v = a * ((1 + 1/a)^v - 1)`. At `a=1/2`, this becomes `(3^v-1)/2`. The difference between adjacent estimates is `n_(v+1)-n_v=3^v`, so the corresponding increment threshold is the reciprocal spacing represented over the fixed draw domain `3^30`: `3^(30-v)` values pass. Each primary port stores the current threshold and divides it by three only when the state increments; this keeps the update constant-time and exact.

The existing base-2 package fixes `a=1`, uses a `2^53` draw domain, and decodes `2^v-1`. This package uses a different transition schedule and decoder while remaining in the same generalized Morris family. The independent oracle derives each exact threshold from the gap between adjacent decoded estimates rather than using the primary rolling-threshold recurrence.

## Source and rights

The [Algorithm Archive chapter](https://www.algorithm-archive.org/contents/approximate_counting/approximate_counting.html) provides the tunable `a` equations and describes the `a=1/2` setting. Robert Morris's paper, [“Counting Large Numbers of Events in Small Registers”](https://doi.org/10.1145/359619.359627), is the historical reference. The sources are used for algorithm ideas only; the ports, contract, workload, and references are original. See [`RIGHTS.md`](RIGHTS.md).

## Workload and static inventory

[`workload.json`](workload.json) includes the empty tape, strict threshold boundaries, the maximum update count, malformed frames and draws, null input/output, and short output capacity. [`verify_workload.py`](verify_workload.py) checks metadata, all ten exported source paths, required fixture coverage, and exact agreement with both references. It does not compile or execute a language port.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/morris_approximate_counter_base_three.c`](../../../c/m/morris_approximate_counter_base_three.c) |
| C3 | [`c3/m/morris_approximate_counter_base_three.c3`](../../../c3/m/morris_approximate_counter_base_three.c3) |
| C++ | [`cpp/m/morris_approximate_counter_base_three.cpp`](../../../cpp/m/morris_approximate_counter_base_three.cpp) |
| Elisa | [`elisa/m/morris_approximate_counter_base_three.elisa`](../../../elisa/m/morris_approximate_counter_base_three.elisa) |
| Mojo | [`mojo/m/morris_approximate_counter_base_three.mojo`](../../../mojo/m/morris_approximate_counter_base_three.mojo) |
| Nim | [`nim/m/morris_approximate_counter_base_three.nim`](../../../nim/m/morris_approximate_counter_base_three.nim) |
| Odin | [`odin/m/morris_approximate_counter_base_three.odin`](../../../odin/m/morris_approximate_counter_base_three.odin) |
| Rust | [`rust/m/morris_approximate_counter_base_three.rs`](../../../rust/m/morris_approximate_counter_base_three.rs) |
| V | [`v/morris_approximate_counter_base_three.v`](../../../v/morris_approximate_counter_base_three.v) |
| Zig | [`zig/m/morris_approximate_counter_base_three.zig`](../../../zig/m/morris_approximate_counter_base_three.zig) |
