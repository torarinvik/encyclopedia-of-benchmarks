# RSBench Doppler cross-section lookup

This package isolates one deterministic microscopic cross-section lookup from the pinned DOE ProxyApps C RSBench source. The upstream launcher defaults to Doppler broadening; the bounded contract retains its per-window pole scan, `calculate_sig_T` factor construction, and `fast_nuclear_W` choice between the Abrarov approximation and the three-term QUICK_W asymptotic expansion. It omits random table generation, material selection, threading, I/O, and timing.

## Contract

The `i64_array_float64` ABI is `double doe_rsbench_doppler_xs(const int64_t *input, size_t length)`. Input is `[n_windows,n_poles,numL,energy_q, (bg_T_q,bg_A_q,bg_F_q,start,end)*n_windows, pseudo_K0RS_q*numL, (EA_re_q,EA_im_q,RT_re_q,RT_im_q,RA_re_q,RA_im_q,RF_re_q,RF_im_q,l_value)*n_poles]`. Every `_q` field is decoded as the signed integer divided by 1,000,000. Window pole ranges are half-open, matching the source's `i < w.end` loop. The energy maps to `int(E / (1.0 / n_windows))`; an exact endpoint at `E=1` uses the last window. A selected pole with exactly `Z=0` is outside the bounded domain because the source approximation is singular there; the ports return the invalid-result sentinel.

There are 1–4 windows, 0–8 poles, and 1–4 angular-momentum factors. Background and pseudo-K0RS values are in `[0,1]`; pole components are in `[0,152.5]`; each `l_value` is in `[0,numL)`. Each window has `0 <= start <= end <= n_poles`. The output combines all four source channels as `sigT + 2*sigA + 3*sigF + 5*sigE`, with `sigE = sigT - sigA`. Invalid input or a non-finite result returns `-1e300`. Compare valid results with absolute tolerance `1e-9` and relative tolerance `1e-12` to account for platform math-library differences.

Ports keep the source expression order in the complex Abrarov and asymptotic formulas, angular factor construction, and per-pole channel accumulation. Fixed-point input makes fixtures deterministic; the output itself remains binary64.

## Workload and oracle

[`workload.json`](workload.json) exercises the small-|Z| Abrarov path, the asymptotic path, all four `l` factors, endpoint window selection, invalid window bounds, malformed length, and null input. The pole strengths are zero in the branch-selection fixtures so their expected scalar values remain exact while the selected approximation path is still evaluated. [`benchmarks/doe_rsbench_doppler_xs_oracle.py`](../../doe_rsbench_doppler_xs_oracle.py) independently computes the complex approximation and channel updates.

## Ports

| Language | Source |
|---|---|
| C | [`c/r/doe_rsbench_doppler_xs.c`](../../../c/r/doe_rsbench_doppler_xs.c) |
| C3 | [`c3/r/doe_rsbench_doppler_xs.c3`](../../../c3/r/doe_rsbench_doppler_xs.c3) |
| C++ | [`cpp/r/doe_rsbench_doppler_xs.cpp`](../../../cpp/r/doe_rsbench_doppler_xs.cpp) |
| Elisa | [`elisa/r/doe_rsbench_doppler_xs.elisa`](../../../elisa/r/doe_rsbench_doppler_xs.elisa) |
| Nim | [`nim/r/doe_rsbench_doppler_xs.nim`](../../../nim/r/doe_rsbench_doppler_xs.nim) |
| Odin | [`odin/r/doe_rsbench_doppler_xs.odin`](../../../odin/r/doe_rsbench_doppler_xs.odin) |
| Rust | [`rust/r/doe_rsbench_doppler_xs.rs`](../../../rust/r/doe_rsbench_doppler_xs.rs) |
| V | [`v/r/doe_rsbench_doppler_xs.v`](../../../v/r/doe_rsbench_doppler_xs.v) |
| Zig | [`zig/r/doe_rsbench_doppler_xs.zig`](../../../zig/r/doe_rsbench_doppler_xs.zig) |

## Provenance and license

The source is pinned to [`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/RSBench) commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher builds `glibc_compat_rand.c`, `init.c`, `io.c`, `main.c`, `material.c`, `utils.c`, and `xs_kernel.c`, and runs `-s small -l 100000 -p 1000 -w 1000`. `io.c` sets Doppler mode on by default. The package maps the default `calculate_micro_xs_doppler` path and its helpers from `xs_kernel.c` to a deterministic synthetic single-nuclide lookup; it does not claim to reproduce the launcher-scale simulation.

The source is distributed under the MIT License. The complete notice is included in each port and in [`LICENSE`](LICENSE).
