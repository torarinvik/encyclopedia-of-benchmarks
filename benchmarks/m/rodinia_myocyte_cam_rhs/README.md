# Rodinia Myocyte CaM/CaMKII RHS

`rodinia_myocyte_cam_rhs` isolates the source `kernel_cam` reaction-rate update from Rodinia's CUDA Myocyte model. For one bounded state vector, it evaluates the 15 calmodulin/CaMKII/calcineurin state derivatives and the source's calcium-buffer communication term, then returns a weighted checksum of those 16 derivatives. It does not execute the 91-state solver, time integration, neighboring-cell coupling, or CUDA launch and allocation code.

## Contract

The package uses the `i64_array_float64` ABI and exported symbol `rodinia_myocyte_cam_rhs`. The exact input is 22 signed 64-bit integers:

`[Ca_u, K_u, Mg_u, Btot_u, CaMKIItot_u, CaNtot_u, PP1tot_u, CaM_u, Ca2CaM_u, Ca4CaM_u, CaMB_u, Ca2CaMB_u, Ca4CaMB_u, Pb2_u, Pb_u, Pt_u, Pt2_u, Pa_u, Ca4CaN_u, CaMCa4CaN_u, Ca2CaMCa4CaN_u, Ca4CaMCa4CaN_u]`

Each value is in millionths and decoded as `f32(f32(raw) / f32(1,000,000))`. Bounds are Ca `[0,100]`, K `[100,200]`, Mg `[0.5,5]`, and totals and states `[0,10]`. Invalid length or values return `-1e300`.

The source's named `float` values and intermediate assignments round to binary32. Its unsuffixed constants promote the Kd expressions, calcium square, selected reaction-rate expressions, `kbt`, and derivative scaling to binary64; those results round back to binary32 at their source assignment points. The package preserves those promotions and the source order of reaction, derivative, and Ca-buffer communication accumulation. The observable result is the ascending sum `Σ(i+1)*double(d[i])`, where `d[0..15]` are the source-order binary32 derivative values. No output quantization is applied.

The static workload includes zero-calcium, zero-state cases on both sides of the source Mg branch. Every derivative and the checksum are exactly zero in those cases. The independent oracle in `benchmarks/rodinia_myocyte_cam_rhs_oracle.py` computes arbitrary bounded cases for generated verifier coverage.

## Provenance and rights

- Pinned source: [`utcs-scea/rodinia/cuda/myocyte`](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/myocyte), commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- Kernel: `kernel_cam` in the Myocyte CUDA source subtree.
- The complete University of Virginia BSD-3-Clause terms and Rodinia citation list are included in [`LICENSE.txt`](LICENSE.txt). The nine ports are clean-room implementations; they contain no copied CUDA wrapper or source comments.
- Rodinia citation: S. Che et al., “Rodinia: A Benchmark Suite for Heterogeneous Computing,” IISWC 2009. The source license also lists the Myocyte systems-biology publication; see `LICENSE.txt`.
