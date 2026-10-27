# Fixed-point rank-one noisy power iteration

This package is a bounded deterministic projection of the Noisy Power Method
in “Private Spectral Analysis,” DOI
[`10.1007/978-1-4939-2864-4_552`](https://doi.org/10.1007/978-1-4939-2864-4_552),
Fig. 1. It fixes the sketch dimension to one vector: each iteration computes
`y = A*x + sigma*z`, then performs the rank-one QR step by normalizing `y`.
The initial vector and every noise vector are supplied as fixed-point inputs,
so the benchmark records one deterministic replay rather than drawing random
values.

All values use scale `S = 1,000,000`. Input is
`[n,L,sigma,A_row_major...,x0...,z1..., ...,zL...]` with `2 <= n <= 4`,
`1 <= L <= 4`, symmetric `A` and `|A_ij| <= S`, `0 <= sigma <= S`,
`z_l,i` in `[-2S,2S]`, and `sum(x0_i^2) = S^2`. Each step computes
`y_i = trunc0((sum_j A_ij*x_j + sigma*z_l,i)/S)`,
`r = floor_sqrt(sum_i y_i^2)`, and
`x_i = trunc0(y_i*S/r)`. `trunc0` means truncation toward zero. An iteration
with `r=0` is invalid. Output is the final fixed-point vector as `n` signed
little-endian i64 values; invalid input or a zero iterate returns `-1`, while
null output or insufficient capacity returns `-2` without writing.

The profile pins the recurrence with integer arithmetic to avoid floating
drift across ports. It does not generate Gaussian noise, recompute sigma from
privacy parameters, or claim differential privacy, a Gaussian distribution,
or the chapter's utility bounds. It is distinct from local spectral norm and
QR decomposition benchmarks: those do not perform this supplied-noise
iterative update.

| Language | Port |
|---|---|
| C | `c/p/private_noisy_power_iteration.c` |
| C3 | `c3/p/private_noisy_power_iteration.c3` |
| C++ | `cpp/p/private_noisy_power_iteration.cpp` |
| Elisa | `elisa/p/private_noisy_power_iteration.elisa` |
| Nim | `nim/p/private_noisy_power_iteration.nim` |
| Odin | `odin/p/private_noisy_power_iteration.odin` |
| Rust | `rust/p/private_noisy_power_iteration.rs` |
| V | `v/p/private_noisy_power_iteration.v` |
| Zig | `zig/p/private_noisy_power_iteration.zig` |
