# Monte Carlo pi estimate

This benchmark measures the serial point-classification and estimate calculation from the pinned Go `MonteCarloPi` function. The source's time-seeded random-number generation is replaced by an explicit sequence of sample points so every language receives the same draws. The concurrent variant is outside this contract.

## Contract

Input is `[random_points, x0, y0, x1, y1, ...]`. `random_points` is an exact integer from 1 through 64. Each supplied coordinate is one of `{0, 0.25, 0.5, 0.75}`; all values are possible `rand.Float64()` outputs in `[0, 1)`. The input contains exactly `1 + 2*random_points` values; the maximum valid length is 129 and 130 is the maximum parseable length for an extra-value probe. Coordinates stand in for consecutive source draws: x first, then y, for each point.

For each point, evaluate `x*x + y*y <= 1` in that order and count it as inside when the comparison is true. The allowed coordinates are exact binary fractions; every pair stays at least 0.125 away from the boundary, keeping the inside/outside classification stable across implementations. Return `float64(inside) / float64(random_points) * 4`, preserving the source division-then-multiplication order. The output contains one finite float64. Compare with absolute and relative tolerances of `1e-12`.

The source does not handle a zero sample count as a finite estimate; this workload restricts the count to 1 through 64. Malformed input, nonfinite values, a coordinate outside the declared set, or a sample count outside the declared range returns `-1` before output checks. A null output pointer or capacity below one element returns `-2` after input validation. Errors write no output values.

The independent oracle is [`../../montecarlopi_oracle.py`](../../montecarlopi_oracle.py). The workload includes closest allowed inside and outside pairs, all-in/all-out samples, maximum count, malformed frames, null buffers, and output-capacity edges.

## Pinned source

- Go [`montecarlopi.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pi/montecarlopi.go), specifically serial `MonteCarloPi`. The benchmark supplies the values returned by its `Float64` calls; it excludes the time-seeded RNG setup and `MonteCarloPiConcurrent` worker behavior.

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/montecarlopi.c`](../../../c/m/montecarlopi.c) |
| C3 | [`c3/m/montecarlopi.c3`](../../../c3/m/montecarlopi.c3) |
| C++ | [`cpp/m/montecarlopi.cpp`](../../../cpp/m/montecarlopi.cpp) |
| Elisa | [`elisa/m/montecarlopi.elisa`](../../../elisa/m/montecarlopi.elisa) |
| Nim | [`nim/m/montecarlopi.nim`](../../../nim/m/montecarlopi.nim) |
| Odin | [`odin/m/montecarlopi.odin`](../../../odin/m/montecarlopi.odin) |
| Rust | [`rust/m/montecarlopi.rs`](../../../rust/m/montecarlopi.rs) |
| V | [`v/m/montecarlopi.v`](../../../v/m/montecarlopi.v) |
| Zig | [`zig/m/montecarlopi.zig`](../../../zig/m/montecarlopi.zig) |
