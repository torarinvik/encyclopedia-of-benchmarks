# DOE SimpleMOC quadratic-source attenuation

This package isolates one quadratic-source transport attenuation step from
SimpleMOC's `attenuate_fluxes` kernel. It reconstructs the source coefficients
from a three-sample axial stencil, computes the source's table-interpolated
`1-exp(-tau)` value, integrates the flux along one segment, updates the fine
region tally, and computes the outgoing angular flux for each energy group.
The fixed table profile uses precision `0.01`, maximum optical thickness `10`,
and 353 intervals, as in the pinned source. The interpolation index expression
also preserves the source's `0.5f * dx` offset.

The original transport sweep selects the neighboring samples and relative
height from track geometry. This bounded profile supplies those three source
samples and the already-centered offset directly. It excludes random source
and geometry initialization, complete track traversal, source iteration,
threading, MPI, file I/O, and timing. The result is a deterministic kernel
profile, not a full SimpleMOC simulation score.

## Contract

The `i64_array_float64` ABI is
`double doe_simplemoc_quadratic_attenuation(const int64_t *input, size_t length)`.
Input is `[groups, zin_q, dz_q, ds_q, mu_q, azimuth_weight_q,
polar_weight_q, (source_prev_q, source_center_q, source_next_q, sigma_t_q,
psi_in_q, tally_in_q)*groups]`. Every `_q` value is a signed fixed-point
integer in units of 1,000,000 and is converted to binary32 before the source
arithmetic. There are one to four groups and the exact input length is
`7 + 6*groups`.

The relative offset satisfies `abs(2*zin) <= dz`; `dz` is in `[0.01, 10]`,
`ds` in `[0.001, 10]`, and total cross section in `[0.1, 10]`. Direction cosine
and azimuth/polar weights are in `[0,1]`; incoming angular flux and initial
tally are nonnegative. Source samples may be signed. Each fixed-point field
has magnitude at most 10. Optical thickness `tau=sigma_t*ds` must be in
`(0,10]`. Invalid input returns `-1e300`.

For each group, the port preserves source-order binary32 arithmetic for
`q0/q1/q2`, flux-integral construction, tally accumulation, and outgoing
`psi`. It returns the binary32 checksum
`sum((group_index+1)*(tally_out+psi_out))` promoted to binary64. The checksum
keeps both updated outputs observable through this suite's scalar ABI. Valid
results use absolute tolerance `2e-4` and relative tolerance `2e-6` for
platform math-library differences in the exponential table.

## Workload and oracle

[`workload.json`](workload.json) covers constant, linear, and quadratic source
stencils, the maximum four-group case, table interpolation, malformed input,
invalid geometry/physical bounds, and null input.
[`benchmarks/doe_simplemoc_quadratic_attenuation_oracle.py`](../../doe_simplemoc_quadratic_attenuation_oracle.py)
reproduces the binary32 expression order and table profile independently.

## Ports

| Language | Source |
|---|---|
| C | [`c/d/doe_simplemoc_quadratic_attenuation.c`](../../../c/d/doe_simplemoc_quadratic_attenuation.c) |
| C3 | [`c3/d/doe_simplemoc_quadratic_attenuation.c3`](../../../c3/d/doe_simplemoc_quadratic_attenuation.c3) |
| C++ | [`cpp/d/doe_simplemoc_quadratic_attenuation.cpp`](../../../cpp/d/doe_simplemoc_quadratic_attenuation.cpp) |
| Elisa | [`elisa/d/doe_simplemoc_quadratic_attenuation.elisa`](../../../elisa/d/doe_simplemoc_quadratic_attenuation.elisa) |
| Nim | [`nim/d/doe_simplemoc_quadratic_attenuation.nim`](../../../nim/d/doe_simplemoc_quadratic_attenuation.nim) |
| Odin | [`odin/d/doe_simplemoc_quadratic_attenuation.odin`](../../../odin/d/doe_simplemoc_quadratic_attenuation.odin) |
| Rust | [`rust/d/doe_simplemoc_quadratic_attenuation.rs`](../../../rust/d/doe_simplemoc_quadratic_attenuation.rs) |
| V | [`v/d/doe_simplemoc_quadratic_attenuation.v`](../../../v/d/doe_simplemoc_quadratic_attenuation.v) |
| Zig | [`zig/d/doe_simplemoc_quadratic_attenuation.zig`](../../../zig/d/doe_simplemoc_quadratic_attenuation.zig) |

## Provenance and license

The source is pinned to [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/SimpleMOC)
commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, particularly
`solver.c::attenuate_fluxes`, `utils.c::buildExponentialTable`, and
`solver.c::interpolateTable`. The launcher selects quadratic source expansion
with `axial_exp=2` and builds `solver.c`; random initialization and the full
one-iteration proxy application are excluded from this bounded workload.

The source is distributed under the MIT License, copyright John Tramm (2014).
The full notice appears in each port and in [`LICENSE`](LICENSE).
