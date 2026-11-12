# Marsaglia polar normal transform

Transform a supplied deterministic tape of 32-bit integer draws into a pair of
standard normal values with the Marsaglia polar method. Each draw `d` maps to
`u = d / 2^31 - 1`, covering the discrete grid in `[-1, 1)`. For each pair,
compute `s = u1*u1 + u2*u2`. Reject the pair when `s <= 0` or `s >= 1`; for an
accepted pair return
`(u1*sqrt(-2*log(s)/s), u2*sqrt(-2*log(s)/s))`.

## Contract

The `float64_slice_io` symbol is `marsaglia_polar_normal(input, input_length,
output, output_capacity)`. Input is a finite binary64 array encoded as
`[draw_count, attempt_cap, draw_0, ..., draw_(draw_count-1)]`. Every value must
be an exact integer. `draw_count` is even and in `[2, 128]`; `attempt_cap` is in
`[1, 64]`; the tape must contain at least `2*attempt_cap` draws; and each draw
is in `[0, 2^32-1]`. The exact input length is `2 + draw_count`.

One attempt consumes exactly two consecutive draws. The method stops at the
first accepted pair, leaving later tape values unused, or stops after exactly
`attempt_cap` rejected pairs. If no pair is accepted, the function returns
`-1` and writes nothing. This status is also used for malformed input. A
successful result writes the two values in pair order and returns `2`; a null
or short output buffer returns `-2` without writing. Output capacity is
measured in binary64 elements. The maximum input has 130 elements; output has
two elements. Runtime is `O(attempt_cap)` with constant auxiliary space.

The oracle uses 80-digit `Decimal` arithmetic for the mapping, logarithm, and
square root, independently of the ports' binary64 math calls. Its API is
`expected_output(values, output_capacity=None, output_is_null=False,
input_length=None) -> (status, pair)`. `expected_result(...)` returns only the
status, `draws_consumed(values)` reports tape consumption, and
`certificate_holds(values, candidate)` checks both outputs within `1e-12`
absolute and relative tolerance.

This port returns both values from each accepted polar pair directly. It does
not keep a cached second value between calls. The polar rejection and
`sqrt/log` transform make it a separate workload from the Cartesian
Box–Muller `sqrt/log/sin/cos` transform and from scalar Gaussian density.

## Provenance

Algorithm overview: [University of Waterloo — Normal Distributions](https://ece.uwaterloo.ca/~dwharder/icsrts/Simulations/Normal_distributions/).
The page distinguishes the Marsaglia polar method from the Box–Muller method
and describes the polar method as avoiding the two trigonometric evaluations.
The ports and oracle implement the mathematical transform clean-room from the
bounded contract; no upstream code or test data was copied.

[`workload.json`](workload.json) covers immediate acceptance, outside-circle
and degenerate-pair rejection, the `s=1` boundary, rejection-cap exhaustion,
unused tape suffixes, malformed tapes, and output-capacity errors.

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/marsaglia_polar_normal.c`](../../../c/m/marsaglia_polar_normal.c) |
| C3 | [`c3/m/marsaglia_polar_normal.c3`](../../../c3/m/marsaglia_polar_normal.c3) |
| C++ | [`cpp/m/marsaglia_polar_normal.cpp`](../../../cpp/m/marsaglia_polar_normal.cpp) |
| Elisa | [`elisa/m/marsaglia_polar_normal.elisa`](../../../elisa/m/marsaglia_polar_normal.elisa) |
| Mojo | [`mojo/m/marsaglia_polar_normal.mojo`](../../../mojo/m/marsaglia_polar_normal.mojo) |
| Nim | [`nim/m/marsaglia_polar_normal.nim`](../../../nim/m/marsaglia_polar_normal.nim) |
| Odin | [`odin/m/marsaglia_polar_normal.odin`](../../../odin/m/marsaglia_polar_normal.odin) |
| Rust | [`rust/m/marsaglia_polar_normal.rs`](../../../rust/m/marsaglia_polar_normal.rs) |
| V | [`v/m/marsaglia_polar_normal.v`](../../../v/m/marsaglia_polar_normal.v) |
| Zig | [`zig/m/marsaglia_polar_normal.zig`](../../../zig/m/marsaglia_polar_normal.zig) |
