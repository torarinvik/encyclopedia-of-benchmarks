# Exponential of a Set Power Series

This package computes the exponential of a square-free multivariate
polynomial over `F_998244353`. Products that repeat a variable vanish because
the algebra is reduced modulo `x_i^2=0` for every variable.

## Bounded contract

The `i64_array_bytes_output` input is `[N, b_0, ..., b_(2^N-1)]`, where masks
are in increasing integer order, `0<=N<=5`, each coefficient is a residue in
`[0,998244352]`, and `b_0=0`. The result is the `2^N` coefficients of
`exp(f)=sum(f^m/m!, m=0..N)` in the same mask order, encoded as little-endian
signed 64-bit integers. Success returns `8*2^N` bytes. Malformed input
returns `-1`; a null output or a capacity smaller than the full result returns
`-2` without writes.

## Algorithm

Let `c[S]` be the coefficient of monomial `prod(x_i for i in S)` in `exp(f)`.
The square-free product rule and the degree operator give

`|S| c[S] = sum(T subset S, T nonempty) |T| b[T] c[S\T]`.

The primary ports enumerate each nonempty submask `T` for every `S`, giving
`O(3^N)` time and `O(2^N)` coefficient storage. Since `N<=5`, every divisor
`1..N` is invertible modulo the prime. The independent oracle enumerates set
partitions of each mask and sums each partition's product of block
coefficients. It lists each unordered partition once; the corresponding
`m!` ordered terms in `f^m` cancel the `1/m!` factor.

The official task allows `N<=20`; the local limit keeps the exhaustive
submask recurrence small and does not claim official maximum-scale
performance. This operation differs from `fast_subset_convolution`, which
multiplies two supplied set functions but does not compute a set-series
exponential.

## Provenance and rights

The operation, square-zero ideal, input precondition, and modulus come from
Library Checker’s [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/set_power_series/exp_of_set_power_series/task.md)
and [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/set_power_series/exp_of_set_power_series/info.toml).
The upstream repository is Apache-2.0. The bounded profile, code, fixtures,
and prose are clean-room; see [RIGHTS.md](RIGHTS.md).

The package has primary and independent oracles, a named fixture workload,
and a static ten-port inventory checker. Root-level suite registration is
complete in the `i64_array_bytes_output` runner and verifier. No programs,
tests, checkers, builds, compilers, or benchmarks were run during integration.

| Language | Source |
|---|---|
| C | [c/e/exp_of_set_power_series.c](../../../c/e/exp_of_set_power_series.c) |
| C3 | [c3/e/exp_of_set_power_series.c3](../../../c3/e/exp_of_set_power_series.c3) |
| C++ | [cpp/e/exp_of_set_power_series.cpp](../../../cpp/e/exp_of_set_power_series.cpp) |
| Elisa | [elisa/e/exp_of_set_power_series.elisa](../../../elisa/e/exp_of_set_power_series.elisa) |
| Mojo | [mojo/e/exp_of_set_power_series.mojo](../../../mojo/e/exp_of_set_power_series.mojo) |
| Nim | [nim/e/exp_of_set_power_series.nim](../../../nim/e/exp_of_set_power_series.nim) |
| Odin | [odin/e/exp_of_set_power_series.odin](../../../odin/e/exp_of_set_power_series.odin) |
| Rust | [rust/e/exp_of_set_power_series.rs](../../../rust/e/exp_of_set_power_series.rs) |
| V | [v/e/exp_of_set_power_series.v](../../../v/e/exp_of_set_power_series.v) |
| Zig | [zig/e/exp_of_set_power_series.zig](../../../zig/e/exp_of_set_power_series.zig) |
