# Circular mean direction

Compute the direction of the resultant of unit vectors for a bounded sequence
of angles. This is the conventional circular mean direction
`atan2(sum(sin(theta_i)), sum(cos(theta_i)))`. It differs from taking the
ordinary arithmetic mean of angles, which fails across the wrap boundary. It
also differs from the L1 “true circular mean,” which minimizes absolute
angular distance; this package does not compute that objective.

## Contract

The `float64_slice_io` input is `[N, theta_0, ..., theta_(N-1)]`, where `N` is
an exactly integral binary64 value in `1..=64` and each angle is a finite
radian value in `[-8π, 8π]`. The exact input length is `N+1`; the maximum valid
length is 65 and the package accepts a 66-value parseable frame so an extra
trailing value can be rejected. Each angle is reduced with the shared
IEEE-754 binary64 `π` and `2π` constants to `[-π, π)` using
`theta - floor((theta + π)/(2π))*2π`; the binary64 `+π` constant maps to `-π`.

The primary adds `(cos(theta), sin(theta))` in input order with independent
Kahan compensation for each coordinate. If the resultant magnitude
`hypot(sum_cos, sum_sin)` is at most `N*2^-28`, the direction is undefined and
the call returns `-1` without writing output. Otherwise it writes one value,
`atan2(sum_sin, sum_cos)`, normalized to `[-π, π)`, and returns `1`. Invalid
input returns `-1`; valid input with a null output pointer or capacity below
one returns `-2`. Input validation precedes output validation. Empty input,
`N=0`, nonintegral counts, trailing or missing values, nonfinite angles, and
angles outside the stated interval are invalid.

The primary oracle uses the same sequential compensated-vector method as the
ports. The independent oracle evaluates trigonometric series with decimal
arithmetic and reduces those high-precision unit vectors, then converts the
resultant direction to binary64. The suite tolerance is `1e-12` absolute and
relative. Workload cases cover ordinary means, the wrap boundary, equivalent
multi-turn inputs, a near-zero resultant on each side of the cutoff, malformed
frames, error precedence, and null/short output.

RosettaGit's public task-title index lists `Averages/Mean angle`; that title
was used only to discover the gap. No task statement, examples, submissions,
tests, or code were consulted. The formula and circular-data distinction come
from the primary and independent sources below.

## Sources

- Utrecht University, [Tutorial 2: Circular descriptives](https://cdm.sites.uu.nl/wp-content/uploads/sites/31/2018/06/Tutorial2-descriptives.pdf), for mean direction from summed sine and cosine coordinates.
- Brigham Young University Center for Remote Sensing, [True Circular Mean](https://www.scp.byu.edu/mers/circularmean.html), for the conventional resultant-direction definition and its distinction from the L1 circular mean.

## Ports

| Language | Source |
|---|---|
| C | [`c/c/circular_mean_direction.c`](../../../c/c/circular_mean_direction.c) |
| C3 | [`c3/c/circular_mean_direction.c3`](../../../c3/c/circular_mean_direction.c3) |
| C++ | [`cpp/c/circular_mean_direction.cpp`](../../../cpp/c/circular_mean_direction.cpp) |
| Elisa | [`elisa/c/circular_mean_direction.elisa`](../../../elisa/c/circular_mean_direction.elisa) |
| Mojo | [`mojo/c/circular_mean_direction.mojo`](../../../mojo/c/circular_mean_direction.mojo) |
| Nim | [`nim/c/circular_mean_direction.nim`](../../../nim/c/circular_mean_direction.nim) |
| Odin | [`odin/c/circular_mean_direction.odin`](../../../odin/c/circular_mean_direction.odin) |
| Rust | [`rust/c/circular_mean_direction.rs`](../../../rust/c/c/circular_mean_direction.rs) |
| V | [`v/c/circular_mean_direction.v`](../../../v/c/circular_mean_direction.v) |
| Zig | [`zig/c/circular_mean_direction.zig`](../../../zig/c/circular_mean_direction.zig) |
