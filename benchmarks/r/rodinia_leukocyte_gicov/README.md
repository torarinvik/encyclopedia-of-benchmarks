# Rodinia Leukocyte GICOV score

`rodinia_leukocyte_gicov` isolates the per-pixel GICOV scoring recurrence in the pinned Rodinia Leukocyte CUDA implementation. It keeps the seven-ellipse maximum and source-order single-precision sum/Welford sample-variance work. The profile supplies already projected directional-gradient samples, so image-gradient loads, ellipse-coordinate/trigonometric table generation, dilation, active-contour tracking, video input and CUDA launch setup are outside the measured call.

## Contract

The ABI is `i64_array_float64`, exported as `rodinia_leukocyte_gicov`. Input is `[point_count, row_0[point_count], ..., row_6[point_count]]`, with exactly seven sample rows. `point_count` is 2 through 16. Each signed sample integer is bounded by `[-1_000_000, 1_000_000]` and decoded in source precision as `f32(f32(raw) / f32(1_000_000))`. A row represents the source expression `grad_x*cos_angle + grad_y*sin_angle` after that projection has been evaluated. Rows are the seven source ellipse stencils in their source order.

For each row, the implementation accumulates `sum`, running `mean`, and `M2` in binary32 using the source's update order. It then overwrites the running mean with `sum/N`, computes sample variance `M2/(N-1)`, computes `(mean*mean)/variance` in binary32, and updates a maximum initialized to zero. The result is this maximum promoted to binary64. Rows that are constant after binary32 decoding have zero variance and divide by zero in the source kernel; they are excluded from this finite-result profile and return `-1e300`. Invalid length, point count, or sample bounds also return `-1e300`.

The static workload contains the hand-solvable two-point row set whose largest score is exactly 4.5, plus malformed and zero-variance cases. The independent oracle in `benchmarks/rodinia_leukocyte_gicov_oracle.py` reproduces binary32 rounding while using a separate Python implementation of the row reduction.

## Provenance and rights

- Pinned source: [`utcs-scea/rodinia/cuda/leukocyte/CUDA/find_ellipse_kernel.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/leukocyte/CUDA/find_ellipse_kernel.cu), commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`, function `GICOV_kernel`.
- The ports are clean-room implementations of the mathematical recurrence and do not copy CUDA wrapper code or source comments. The full applicable University of Virginia BSD-3-Clause terms and Rodinia citation list are in [`LICENSE.txt`](LICENSE.txt). This package does not include or use the separately licensed Meschach dependency.
- Rodinia citation: S. Che et al., “Rodinia: A Benchmark Suite for Heterogeneous Computing,” IISWC 2009. The Leukocyte source license additionally requests the paper by M. Boyer et al. on accelerating Leukocyte tracking; see `LICENSE.txt`.
