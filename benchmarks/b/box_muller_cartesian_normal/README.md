# Cartesian Box–Muller normal transform

Generate a pair of independent standard normal values from each pair of supplied
32-bit integer draws with the direct Cartesian Box–Muller transform. For a
radial draw `a` and angular draw `b`, map
`U1 = (a + 1) / 2^32` and `U2 = b / 2^32`, then compute
`r = sqrt(-2 * log(U1))`, `theta = 2*pi*U2`, and return
`(r*cos(theta), r*sin(theta))`.

## Contract

The `float64_slice_io` symbol is `box_muller_cartesian_normal(input,
input_length, output, output_capacity)`. Its finite binary64 input contains
exact integers encoded as `[pair_count, radial_draw_0, angular_draw_0, ...]`.
The pair count is in `[1, 64]`, each draw is in `[0, 2^32-1]`, and the input
length must equal `1 + 2*pair_count`. The output contains two consecutive
samples for every supplied draw pair, ordered with cosine first and sine
second. The largest input has 129 elements and the largest output has 128.

The radial mapping gives `U1` in `(0, 1]`, so the logarithm is always defined;
the angular mapping gives `U2` in `[0, 1)`. No rejection occurs and no random
state is kept between calls. Every pair consumes exactly two tape values. A
malformed tape returns `-1`; a null or undersized output returns `-2` without
writing; success returns the number of output elements. Runtime is
`O(pair_count)` with constant auxiliary space beyond the output buffer.

The oracle uses 90-digit `Decimal` arithmetic for the logarithm, square root,
and a Taylor recurrence for sine and cosine. Its API is
`expected_output(values, output_capacity=None, output_is_null=False,
input_length=None) -> (status, samples)`. `expected_result(...)` returns the
status, `draws_consumed(values)` reports the tape length consumed, and
`certificate_holds(values, candidate)` checks every sample within `1e-12`
absolute and relative tolerance. The independent suite verifier uses direct
binary64 math-library calls.

This is the direct Cartesian transform from Box and Muller's 1958 note. It is
kept separate from [Marsaglia polar](../marsaglia_polar_normal/README.md),
which rejects points outside the unit disk and has a different draw-consumption
profile.

## Provenance

G. E. P. Box and Mervin E. Muller, “A Note on the Generation of Random Normal
Deviates,” *The Annals of Mathematical Statistics* 29(2), 610–611 (1958),
[DOI: 10.1214/aoms/1177706645](https://doi.org/10.1214/aoms/1177706645).
The implementations and bounded integer-tape oracle are clean-room translations
of the mathematical transform; no upstream code or test data was copied.

[`workload.json`](workload.json) covers axis-aligned and quarter-turn outputs,
the `U1=1` endpoint, multiple pairs, malformed tapes, and output errors.

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/box_muller_cartesian_normal.c`](../../../c/b/box_muller_cartesian_normal.c) |
| C3 | [`c3/b/box_muller_cartesian_normal.c3`](../../../c3/b/box_muller_cartesian_normal.c3) |
| C++ | [`cpp/b/box_muller_cartesian_normal.cpp`](../../../cpp/b/box_muller_cartesian_normal.cpp) |
| Elisa | [`elisa/b/box_muller_cartesian_normal.elisa`](../../../elisa/b/box_muller_cartesian_normal.elisa) |
| Mojo | [`mojo/b/box_muller_cartesian_normal.mojo`](../../../mojo/b/box_muller_cartesian_normal.mojo) |
| Nim | [`nim/b/box_muller_cartesian_normal.nim`](../../../nim/b/box_muller_cartesian_normal.nim) |
| Odin | [`odin/b/box_muller_cartesian_normal.odin`](../../../odin/b/box_muller_cartesian_normal.odin) |
| Rust | [`rust/b/box_muller_cartesian_normal.rs`](../../../rust/b/box_muller_cartesian_normal.rs) |
| V | [`v/b/box_muller_cartesian_normal.v`](../../../v/b/box_muller_cartesian_normal.v) |
| Zig | [`zig/b/box_muller_cartesian_normal.zig`](../../../zig/b/box_muller_cartesian_normal.zig) |
