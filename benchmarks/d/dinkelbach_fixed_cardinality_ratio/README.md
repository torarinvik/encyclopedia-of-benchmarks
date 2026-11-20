# Dinkelbach fixed-cardinality maximum ratio

This profile maximizes `sum(a_i)/sum(b_i)` over subsets containing exactly
`K` items. Dinkelbach's method repeatedly solves the associated additive
selection problem at the current ratio. At each step it ranks items by
`a_i*q-p*b_i`, selects the `K` largest scores (breaking ties by original
index), and updates the ratio from the selected sums. The method stops when
the selected residual is zero. This is distinct from fractional knapsack,
which allows fractional item choices, and minimum-mean-cycle algorithms,
which optimize a ratio over directed cycles.

## Contract

The exported scalar symbol is `dinkelbach_fixed_cardinality_ratio`. Input is
`[N,K,(numerator,denominator)*N]`, with `1<=N<=12`, `1<=K<=N`, numerators in
`[0,10000]`, and positive denominators in `[1,10000]`. Exact length is
`2+2N`; the maximum valid and parseable lengths are 26 and 27 signed 64-bit
values. Invalid input returns `-1`.

The iteration starts at `p/q=0/1`. It selects exactly `K` items by descending
integer residual `a_i*q-p*b_i`, ties by lower original index. Let the selected
sums be `P` and `W`. If `P*q-p*W=0`, the optimal ratio is `P/W`; otherwise
the residual is positive and the algorithm continues from the reduced ratio
`P/W`. Each positive step strictly increases the ratio and selects a new
cardinality-`K` subset, so at most `binom(N,K)+1` iterations are needed.

The returned scalar encodes the reduced optimum as
`reduced_numerator*120001+reduced_denominator`. Both selected sums are at most
120,000, so this base makes the reduced pair unambiguous. The language ports
use insertion sorting to rank at most 12 items; primary worst-case time is
`O(binomial(N,K)*N^2)` with `O(N)` space. The independent exhaustive-subset
oracle uses `O(binomial(N,K)*N)` time and `O(N)` space.

## Provenance and rights

The fractional-programming iteration follows W. Dinkelbach, “On Nonlinear
Fractional Programming,” *Management Science* 13(7), 1967, pp. 492–498,
DOI [10.1287/mnsc.13.7.492](https://doi.org/10.1287/mnsc.13.7.492), and the
algorithmic overview in [OI Wiki's fractional programming article](https://oi-wiki.org/misc/frac-programming/).
The OI Wiki page is CC BY-SA 4.0 and carries its stated SATA notice. Sources
are used for the algorithm idea only; this contract, fixtures, oracle, and
language ports are independently authored. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the [Dinkelbach oracle](../../dinkelbach_fixed_cardinality_ratio_oracle.py),
the [exhaustive verifier](../../dinkelbach_fixed_cardinality_ratio_verifier_oracle.py),
and [static package inventory](../../check_dinkelbach_fixed_cardinality_ratio_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/d/dinkelbach_fixed_cardinality_ratio.c`](../../../c/d/dinkelbach_fixed_cardinality_ratio.c) |
| C3 | [`c3/d/dinkelbach_fixed_cardinality_ratio.c3`](../../../c3/d/dinkelbach_fixed_cardinality_ratio.c3) |
| C++ | [`cpp/d/dinkelbach_fixed_cardinality_ratio.cpp`](../../../cpp/d/dinkelbach_fixed_cardinality_ratio.cpp) |
| Elisa | [`elisa/d/dinkelbach_fixed_cardinality_ratio.elisa`](../../../elisa/d/dinkelbach_fixed_cardinality_ratio.elisa) |
| Mojo | [`mojo/d/dinkelbach_fixed_cardinality_ratio.mojo`](../../../mojo/d/dinkelbach_fixed_cardinality_ratio.mojo) |
| Nim | [`nim/d/dinkelbach_fixed_cardinality_ratio.nim`](../../../nim/d/dinkelbach_fixed_cardinality_ratio.nim) |
| Odin | [`odin/d/dinkelbach_fixed_cardinality_ratio.odin`](../../../odin/d/dinkelbach_fixed_cardinality_ratio.odin) |
| Rust | [`rust/d/dinkelbach_fixed_cardinality_ratio.rs`](../../../rust/d/dinkelbach_fixed_cardinality_ratio.rs) |
| V | [`v/d/dinkelbach_fixed_cardinality_ratio.v`](../../../v/d/dinkelbach_fixed_cardinality_ratio.v) |
| Zig | [`zig/d/dinkelbach_fixed_cardinality_ratio.zig`](../../../zig/d/dinkelbach_fixed_cardinality_ratio.zig) |
