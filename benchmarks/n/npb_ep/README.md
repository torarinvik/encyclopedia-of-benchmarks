# NAS Parallel Benchmarks EP kernel

This is a bounded clean-room profile of NASA's Embarrassingly Parallel (EP)
kernel. For each candidate, it advances the 46-bit linear congruential stream
twice, maps both uniforms to `[-1, 1)`, rejects points outside the unit disk,
turns accepted points into a standard-normal pair with the Marsaglia polar
formula, then reduces ten square-annulus counts and the two coordinate sums.

The profile intentionally keeps the stream generation, rejection transform,
histogram, and sums together. It is distinct from the standalone
[`linear_congruential_generator`](../linear_congruential_generator/README.md)
recurrence and [`marsaglia_polar_normal`](../../m/marsaglia_polar_normal/README.md)
supplied-tape transform: those packages do not perform this full stream-and-
reduction kernel.

## Contract

The `float64_slice_io` symbol is `npb_ep(input, input_length, output,
output_capacity)`. Input is two finite exact integers:
`[candidate_pair_count, initial_46_bit_state]`. The candidate count is in
`[1, 4096]`; the initial state is in `[1, 2^46-1]`. Every candidate consumes
exactly two LCG values, including rejected points. The fixed recurrence is
`state = (1220703125 * state) mod 2^46`; each generated uniform is
`state / 2^46`, followed by `coordinate = 2*uniform - 1`.

For `t=x*x+y*y`, reject when `t>1` or `t=0`; the latter is undefined in the
polar scale formula. Accept `0<t<=1` and calculate
`factor=sqrt(-2*log(t)/t)`, `X=x*factor`, and `Y=y*factor`. For each accepted
pair, add `X` and `Y` to their respective sums and increment bin
`floor(max(abs(X),abs(Y)))` when that value is below 10. This implements the
NASA half-open annulus rule `l <= max(abs(X),abs(Y)) < l+1` for bins `l=0..9`.

The output is `[Q0, Q1, ..., Q9, sum_x, sum_y]`. Histogram counts are exact
integer-valued binary64 numbers. Success returns 12; invalid input returns
`-1`; null or insufficient output returns `-2` without writing. The maximum
input length is 2, the output and workspace lengths are 12, runtime is
`O(candidate_pair_count)`, and auxiliary storage is constant.

NASA's canonical EP profile uses seed `271828183` and `2^28` candidate pairs.
This local profile bounds work at 4,096 candidates and takes the starting state
as an input so fixtures can cover both accepted and degenerate candidate
paths. The deterministic accepted-path fixture uses the LCG fixed point
`3*2^44`, for which every mapped coordinate is `0.5`; the degenerate fixture
uses `2^45`, which maps every coordinate to zero. The recurrence, multiplier,
modulus, polar transform, reductions, and annulus boundary rules remain those
of EP.

The oracle uses Python's unbounded integer multiplication modulo `2^46`,
80-digit `Decimal` arithmetic for uniform conversion and the polar transform,
and Decimal coordinate sums. This differs from the ports' split-word modular
multiply and binary64 math. Its API is
`expected_output(values, output_capacity=None, output_is_null=False,
input_length=None) -> (status, bins_and_sums)`. `expected_result(...)` returns
the status, `draws_consumed(values)` returns two per candidate, and
`certificate_holds(values, candidate)` checks exact bins and tolerant sums.

## Provenance

Specification: D. Bailey et al., [*The NAS Parallel Benchmarks*, NASA Ames NAS
Technical Report RNR-94-007](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf),
March 1994, §2.2.1 and §2.3. NASA's [current NPB overview](https://nas.nasa.gov/software/npb.html)
lists EP among the original computational kernels. Implementations and oracle
are clean-room translations of the written algorithm; no reference code or
reference tables were copied.

[`workload.json`](workload.json) covers accepted pairs and sums, degenerate
rejection, malformed seed/count values, and output errors.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/npb_ep.c`](../../../c/n/npb_ep.c) |
| C3 | [`c3/n/npb_ep.c3`](../../../c3/n/npb_ep.c3) |
| C++ | [`cpp/n/npb_ep.cpp`](../../../cpp/n/npb_ep.cpp) |
| Elisa | [`elisa/n/npb_ep.elisa`](../../../elisa/n/npb_ep.elisa) |
| Mojo | [`mojo/n/npb_ep.mojo`](../../../mojo/n/npb_ep.mojo) |
| Nim | [`nim/n/npb_ep.nim`](../../../nim/n/npb_ep.nim) |
| Odin | [`odin/n/npb_ep.odin`](../../../odin/n/npb_ep.odin) |
| Rust | [`rust/n/npb_ep.rs`](../../../rust/n/npb_ep.rs) |
| V | [`v/n/npb_ep.v`](../../../v/n/npb_ep.v) |
| Zig | [`zig/n/npb_ep.zig`](../../../zig/n/npb_ep.zig) |
