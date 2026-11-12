# Rational Approximation with Bounded Components

For a positive rational target `x/y`, return its closest lower and upper reduced fractions whose numerators and denominators are each at most `N`.

## Contract

The scalar byte-output ABI accepts `[N, x, y]`, with every value in `1..1,000,000,000`. It returns four little-endian signed 64-bit integers: `[lower_numerator, lower_denominator, upper_numerator, upper_denominator]`. If no positive feasible fraction lies below the target, the lower bound is `0/1`; if none lies above it, the upper bound is `1/0`. If the reduced target itself fits, both outputs equal it. Invalid input returns `-1`; a null or undersized output buffer returns `-2`.

The search keeps adjacent Stern–Brocot bounds around `x/y`. It compares each mediant using exact cross-products, then jumps across a whole run of left or right steps using the corresponding quotient. Each jump is capped so neither component exceeds `N`. All comparisons fit signed 64-bit arithmetic under the input bounds.

## Relationship to existing fraction benchmarks

This is distinct from [`farey_approximation`](../../f/farey_approximation/README.md), which follows a fixed number of one-step mediants for a decimal in `(0,1)` and returns the final mediant. This package instead finds both optimal neighbors under simultaneous numerator and denominator bounds for an exact rational target. It is also distinct from [`continued_fraction`](../../c/continued_fraction/README.md), which returns the exact continued-fraction coefficients of its rational input. The local [`stern_brocot_tree`](../../s/stern_brocot_tree/README.md) benchmark covers path, LCA, ancestor, and descendant-interval queries rather than bounded rational neighbors.

The [Library Checker task](https://judge.yosupo.jp/problem/rational_approximation) batches up to 100,000 cases; this workload presents each case as one bounded scalar call. See [`workload.json`](workload.json) and the independent continued-fraction oracle at [`benchmarks/rational_approximation_oracle.py`](../../rational_approximation_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rational_approximation.c`](../../../c/r/rational_approximation.c) |
| C3 | [`c3/r/rational_approximation.c3`](../../../c3/r/rational_approximation.c3) |
| C++ | [`cpp/r/rational_approximation.cpp`](../../../cpp/r/rational_approximation.cpp) |
| Elisa | [`elisa/r/rational_approximation.elisa`](../../../elisa/r/rational_approximation.elisa) |
| Mojo | [`mojo/r/rational_approximation.mojo`](../../../mojo/r/rational_approximation.mojo) |
| Nim | [`nim/r/rational_approximation.nim`](../../../nim/r/rational_approximation.nim) |
| Odin | [`odin/r/rational_approximation.odin`](../../../odin/r/rational_approximation.odin) |
| Rust | [`rust/r/rational_approximation.rs`](../../../rust/r/rational_approximation.rs) |
| V | [`v/r/rational_approximation.v`](../../../v/r/rational_approximation.v) |
| Zig | [`zig/r/rational_approximation.zig`](../../../zig/r/rational_approximation.zig) |
