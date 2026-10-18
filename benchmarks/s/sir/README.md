# SIR right-hand side

This benchmark evaluates the pinned Julia SIR model's derivative function for
one state and parameter tuple. It measures the `SIR(du, u, p, t)` right-hand
side only; the DifferentialEquations solver, integration schedule, and plot are
outside the contract.

## Contract

The `float64_slice_io` input is `[S, I, R, beta, k, t]`, exactly six finite
binary64 values. State components `S`, `I`, and `R` are in `[0, 1,000,000]`;
`beta` is in `[0, 0.001]`; `k` is in `[0, 1]`; and `t` is in `[0, 140]`.
These bounds include the pinned notebook's initial conditions and parameter
values while keeping every intermediate finite. `R` and `t` are validated but
do not affect the derivative because the source function does not read them.

The output contains `[dS, dI, dR]`. Preserve the source expression order:
`dS = ((-beta) * S) * I`, `dI = ((beta * S) * I) - (k * I)`, and
`dR = k * I`. The unary negation is applied to `beta` before the two
multiplications in `dS`. The source assigns these derivatives to `du[1]`,
`du[2]`, then `du[3]` and returns the third assignment.

Malformed length, null input, nonfinite or out-of-domain values return `-1`.
Input validation takes precedence over output pointer and capacity checks. For
valid input, a null output pointer or output capacity below three returns `-2`
without writing; capacity of three or more succeeds, writes exactly three
values, and returns `3`. Results use absolute and relative tolerances of
`1e-12`.

The largest valid input has six values; seven values are parseable so a
trailing-value case can be represented. The maximum output length is three.

## Pinned source

The source is pinned at
[`sir.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/pluto_notebooks/sir.jl),
commit `384424b762bbb40d43f31001beeca0c6ffda2f1f`, function `SIR(du, u, p, t)`.
The function unpacks `u` as `(S, I, R)` and `p` as `(beta, k)`, computes the
three derivatives, and does not use `R` or `t`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`sir_oracle.py`](../../sir_oracle.py)

## Ports

| Language | Port |
|---|---|
| C | [`c/s/sir.c`](../../../c/s/sir.c) |
| C3 | [`c3/s/sir.c3`](../../../c3/s/sir.c3) |
| C++ | [`cpp/s/sir.cpp`](../../../cpp/s/sir.cpp) |
| Elisa | [`elisa/s/sir.elisa`](../../../elisa/s/sir.elisa) |
| Nim | [`nim/s/sir.nim`](../../../nim/s/sir.nim) |
| Odin | [`odin/s/sir.odin`](../../../odin/s/sir.odin) |
| Rust | [`rust/s/sir.rs`](../../../rust/s/sir.rs) |
| V | [`v/s/sir.v`](../../../v/s/sir.v) |
| Zig | [`zig/s/sir.zig`](../../../zig/s/sir.zig) |
