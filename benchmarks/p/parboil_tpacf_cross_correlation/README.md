# Parboil TPACF cross-correlation

`parboil_tpacf_cross_correlation` is a bounded clean-room profile of Parboil's `gen_hists` kernel. It cross-correlates two point sets, computes each Cartesian dot product in source order, and bins it against the source's 20 logarithmic angular intervals. It is distinct from nearest-neighbor search and geometric graph construction: the observable is a histogram of angular pair distances.

## Contract

The exported symbol is `parboil_tpacf_cross_correlation`, using the `i64_array_bytes_output` ABI.

- Input: `[data_count, random_count, data_xyz..., random_xyz...]`, with one signed Q1e-6 Cartesian triple per point.
- Each count is in `1..4`, every coordinate integer is in `[-1_000_000, 1_000_000]`, and the exact input length is `2 + 3*(data_count + random_count)` (maximum 26 values).
- Convert each coordinate as `f32(f32(raw) / f32(1_000_000))`.
- Build 21 binary32 thresholds for `k=0..20` from the source expression `cos(pow(10, log10(1) + k/5) / 60 * (pi/180))`; compute the expression in binary64, then round once when storing each threshold as binary32.
- Visit random points in input order, then data points in input order. Round each of `dx*rx`, `dy*ry`, `dz*rz`, their `x+y` sum, and the final `+z` sum to binary32 in that order.
- Binary-search the descending thresholds with `min=0`, `max=20`; if `distance < threshold[min] && distance >= threshold[max]`, increment bin `max-1`. Values outside the source threshold range are ignored.
- Output is 20 bytes, one unsigned histogram count per source bin. The at-most-16 pair workload cannot overflow a byte. Success returns 20; invalid input returns `-1`; null output or capacity below 20 returns `-2` without writes.

The profile isolates one cross-correlation block of `gen_hists`. It excludes input-file parsing and spherical-coordinate conversion, the `dd`/`dr`/`rr` collection wrapper, random-set generation, GPU tiling, shared-memory histogram privatization, and final multi-block reduction. Point coordinates are already Cartesian, as the kernel expects. The independent oracle scans interval boundaries directly instead of using the source binary search.

## Source and rights

Source pin: [`yuhc/gpu-parboil` commit `ccf3d3126f1754ca85528722f4ced5894ccb852b`](https://github.com/yuhc/gpu-parboil/tree/ccf3d3126f1754ca85528722f4ced5894ccb852b), chiefly [`benchmarks/tpacf/src/cuda_base/tpacf_kernel.cu`](https://github.com/yuhc/gpu-parboil/blob/ccf3d3126f1754ca85528722f4ced5894ccb852b/benchmarks/tpacf/src/cuda_base/tpacf_kernel.cu) (`gen_hists`, `initBinB`) and `benchmarks/tpacf/src/base/model.h` (`NUM_BINS`, angular range, bins per decade). The benchmark description cites Landy and Szalay, “Bias and Variance of Angular Correlation Functions,” *Astrophysical Journal* 412:64–71 (1993).

The upstream repository carries the Illinois Open Source License, copyright 2007–2011 Board of Trustees of the University of Illinois; the complete license text is in [`LICENSE.txt`](LICENSE.txt). These ports independently implement the operation and preserve source attribution and the repository notice.

Oracle: [`benchmarks/parboil_tpacf_cross_correlation_oracle.py`](../../parboil_tpacf_cross_correlation_oracle.py). The byte-output runner and independent verifier register this bounded profile and its generated boundary corpus.

## Ports

| Language | File |
|---|---|
| C | [`parboil_tpacf_cross_correlation.c`](../../../c/p/parboil_tpacf_cross_correlation.c) |
| C3 | [`parboil_tpacf_cross_correlation.c3`](../../../c3/p/parboil_tpacf_cross_correlation.c3) |
| C++ | [`parboil_tpacf_cross_correlation.cpp`](../../../cpp/p/parboil_tpacf_cross_correlation.cpp) |
| Elisa | [`parboil_tpacf_cross_correlation.elisa`](../../../elisa/p/parboil_tpacf_cross_correlation.elisa) |
| Nim | [`parboil_tpacf_cross_correlation.nim`](../../../nim/p/parboil_tpacf_cross_correlation.nim) |
| Odin | [`parboil_tpacf_cross_correlation.odin`](../../../odin/p/parboil_tpacf_cross_correlation.odin) |
| Rust | [`parboil_tpacf_cross_correlation.rs`](../../../rust/p/parboil_tpacf_cross_correlation.rs) |
| V | [`parboil_tpacf_cross_correlation.v`](../../../v/p/parboil_tpacf_cross_correlation.v) |
| Zig | [`parboil_tpacf_cross_correlation.zig`](../../../zig/p/parboil_tpacf_cross_correlation.zig) |
