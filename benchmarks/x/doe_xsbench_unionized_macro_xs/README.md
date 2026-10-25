# XSBench unionized-grid macroscopic cross-section lookup

This package isolates one deterministic material cross-section lookup from the
XSBench `calculate_macro_xs` path. It binary-searches a prebuilt unionized energy
grid, reads the selected row of per-nuclide grid pointers, interpolates five
microscopic cross-section channels, and accumulates concentration-weighted
macroscopic channels in material-composition order.

The bounded workload accepts one to four nuclides, two to five energy points
per nuclide, and one material composition containing unique nuclide ids. It
supplies the sorted unionized energy grid and its precomputed pointer matrix as
the original initialization code does. It excludes grid generation, sorting,
pointer-table construction, the random material/energy loop, threading, MPI,
I/O, and timing; it profiles one source-shaped lookup over already-prepared
data.

## Contract

The `i64_array_float64` ABI is
`double doe_xsbench_unionized_macro_xs(const int64_t *input, size_t length)`.
Input is laid out as:

```text
[nuclides, gridpoints, material_nuclides, energy_q,
 (nuclide_id, concentration_q)*material_nuclides,
 union_energy_q*(nuclides*gridpoints),
 pointer_index*(nuclides*gridpoints*nuclides),
 (energy_q, total_xs_q, elastic_xs_q, absorption_xs_q,
  fission_xs_q, nu_fission_xs_q)*(nuclides*gridpoints)]
```

Every `_q` field is a signed fixed-point integer in units of 1,000,000 and is
decoded to binary64. Energies, concentrations, and cross-section channels are
bounded by `[0,1]`. Each per-nuclide grid is strictly increasing. The unionized
grid is the strictly increasing sorted union of all nuclide energies, with no
duplicate energies in this bounded profile. Its pointer matrix is row-major by
union-grid index then nuclide id, and each entry is the pinned source's
`binary_search` result for that union energy. The exact input length is
`4 + 2*material_nuclides + union_count*(7+nuclides)` where
`union_count=nuclides*gridpoints`.

`grid_search` returns the lower union-grid index, clamped to the first or last
bracket at the query boundaries. For each material nuclide, the lookup uses the
pointer stored at that union-grid row. If the pointer equals the final nuclide
grid index, the source shifts the low index back one point before selecting the
high point. The interpolation factor is
`(high.energy-energy)/(high.energy-low.energy)`, and each channel is computed
as `high.xs - factor*(high.xs-low.xs)`. The five interpolated channels are
multiplied by the corresponding concentration and accumulated in material
order.

The scalar output is
`macro_total + 2*macro_elastic + 3*macro_absorption + 5*macro_fission + 7*macro_nu_fission`.
Invalid inputs return `-1e300`. The fixtures use binary-exact values and valid
results are compared with absolute and relative tolerances of `1e-12`.

## Workload and oracle

[`workload.json`](workload.json) covers an interpolated query, the upper union
grid endpoint, malformed pointer data, extra input, and null input.
[`benchmarks/doe_xsbench_unionized_macro_xs_oracle.py`](../../doe_xsbench_unionized_macro_xs_oracle.py)
independently implements the source's union-grid search, per-nuclide pointer
search, interpolation, and material accumulation.

## Ports

| Language | Source |
|---|---|
| C | [`c/x/doe_xsbench_unionized_macro_xs.c`](../../../c/x/doe_xsbench_unionized_macro_xs.c) |
| C3 | [`c3/x/doe_xsbench_unionized_macro_xs.c3`](../../../c3/x/doe_xsbench_unionized_macro_xs.c3) |
| C++ | [`cpp/x/doe_xsbench_unionized_macro_xs.cpp`](../../../cpp/x/doe_xsbench_unionized_macro_xs.cpp) |
| Elisa | [`elisa/x/doe_xsbench_unionized_macro_xs.elisa`](../../../elisa/x/doe_xsbench_unionized_macro_xs.elisa) |
| Nim | [`nim/x/doe_xsbench_unionized_macro_xs.nim`](../../../nim/x/doe_xsbench_unionized_macro_xs.nim) |
| Odin | [`odin/x/doe_xsbench_unionized_macro_xs.odin`](../../../odin/x/doe_xsbench_unionized_macro_xs.odin) |
| Rust | [`rust/x/doe_xsbench_unionized_macro_xs.rs`](../../../rust/x/doe_xsbench_unionized_macro_xs.rs) |
| V | [`v/x/doe_xsbench_unionized_macro_xs.v`](../../../v/x/doe_xsbench_unionized_macro_xs.v) |
| Zig | [`zig/x/doe_xsbench_unionized_macro_xs.zig`](../../../zig/x/doe_xsbench_unionized_macro_xs.zig) |

## Provenance and license

The source is pinned to [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/XSBench)
commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, especially
`CalculateXS.c::grid_search`, `CalculateXS.c::calculate_micro_xs`,
`CalculateXS.c::calculate_macro_xs`, `XSutils.c::binary_search`, and
`GridInit.c::set_grid_ptrs`. Its launcher compiles six C sources with `-lm
-DVERIFICATION` and runs `-s small -g 1250 -l 1000000`.

The pinned source is distributed under the MIT License, Copyright (c) 2012-2013
Argonne National Laboratory. The complete notice is retained in every port and
in [`LICENSE`](LICENSE):

> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
> of the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
> FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
> COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
> IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
> CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
