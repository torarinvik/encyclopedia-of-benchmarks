# Rodinia SRAD v2 diffusion update

`rodinia_srad_v2` isolates the two numerical kernels in Rodinia's CUDA SRAD v2 benchmark. It keeps the speckle-reducing anisotropic diffusion coefficient calculation from `srad_cuda_1` and the divergence-based image update from `srad_cuda_2`. This is a bounded kernel profile, not a reproduction of the random-image, ROI-statistics, CUDA setup, or output-printing wrapper.

## Contract

The package uses the `i64_array_scalar` ABI and symbol `rodinia_srad_v2`. Its input is exactly 258 nonnegative signed-i64 words:

`[lambda_f32_bits, q0sqr_f32_bits, J_0_f32_bits, ..., J_255_f32_bits]`

The 256 image values are row-major values for one 16×16 block. The first two entries and each pixel are the raw IEEE-754 binary32 bit pattern, carried in an i64. Lambda is in `[0.01, 0.1]`; q0sqr is in `[0.01, 1]`; J is in `[1, 1.25]`, a bounded subset of the source's `exp(random_matrix(...))` state range. The source launcher requires dimensions that are multiples of 16; this bounded profile uses the minimum 16×16 domain. The small J and lambda limits keep one source update positive for every admitted stencil.

The first kernel forms north, south, west, and east differences, computes the normalized gradient and Laplacian, derives the local SRAD coefficient, and clamps it to `[0,1]`. Image boundaries replicate the current pixel. The second kernel computes divergence and updates J once. It preserves the pinned source's coefficient choices: north and west use the current cell's coefficient; south and east use the next cell's coefficient, with bottom/right replication. The README and workload call out this source behavior directly.

State variables and named float stores use binary32. Promotion follows the pinned C++ expression rules: `g2`, `l`, `l*l`, `den*den`, and the `q0sqr` denominator are computed as float expressions and stored as floats. In `num`, `g2` is promoted by `0.5`, while the already-computed float `l*l` is promoted by `1.0/16.0`; the assignment rounds `num` back to float. In `den = 1 + (.25*l)`, the unsuffixed literals make that expression binary64 until the float assignment. `qsqr` and the following `den` recurrence remain float arithmetic. In `c = 1.0/(1.0+den)`, the unsuffixed literals promote the division to binary64, followed by a float store. Kernel 2 accumulates `d_sum` in float; the unsuffixed `0.25` promotes the final update expression to binary64, followed by a float store to J. All nine ports and the independent oracle preserve these points. The observable result sums `floor(double(J_final_f32) * 1,000,000 + 0.5)` in row-major order. Invalid frames, non-finite recurrence cases, and values outside the bounded source domain return `-1`.

The profile accepts J and q0sqr explicitly at the kernel boundary. The source's `random_matrix`, `exp`, ROI reduction, and setup are outside the measured call. This keeps the two diffusion kernels deterministic while retaining the source recurrence.

## Provenance and rights

- Pinned repository: [utcs-scea/rodinia](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/srad/srad_v2) at commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- Kernel source: [`srad_kernel.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/srad/srad_v2/srad_kernel.cu); caller/launcher behavior: [`srad.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/srad/srad_v2/srad.cu) and [`run`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/srad/srad_v2/run).
- The complete University of Virginia BSD-3-Clause notice and Rodinia citation list are in [`LICENSE.txt`](LICENSE.txt). This clean-room profile contains no copied source comments or CUDA wrappers.
- Relevant citations: Y. Yu and S. Acton, “Speckle Reducing Anisotropic Diffusion,” *IEEE Transactions on Image Processing*, 11(11), 2002; S. Che et al., “Rodinia: A Benchmark Suite for Heterogeneous Computing,” IISWC, 2009.

The scalar workload includes uniform-state, interior-neighbor, and replicated-corner fixtures. `benchmarks/rodinia_srad_v2_oracle.py` independently evaluates both kernels and the fixed-point checksum.
