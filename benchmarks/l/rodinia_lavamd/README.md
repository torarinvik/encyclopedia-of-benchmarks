# Rodinia LavaMD screened particle interactions

This package extracts the source's `kernel_gpu_cuda` force and potential accumulation for a bounded home box and one neighboring box. It retains the source's actual `r2 = a.v + b.v - dot(a.xyz, b.xyz)` expression, `a2 = 2*alpha*alpha` with `alpha = 0.5`, exponential interaction, and component accumulation order. The source initializes each box with 100 particles and explores up to 26 neighbors; this profile bounds both boxes to four particles and includes one neighbor box.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `rodinia_lavamd`.
- Input: `[home_count, neighbor_count, (v_u, x_u, y_u, z_u, charge_u)...]`, first the home particles, then the neighbor particles. Each component is an unsigned fixed-point value in `[0, 1,000,000]`, scaled by `1e-6` to binary64.
- Both counts are in `1..4`. Each home particle accumulates interactions with all home particles first, then all neighbor particles, in input order. The force state begins at zero, as in the source harness.
- For each pair, evaluate `dot = ax*bx + ay*by + az*bz`, `r2 = av + bv - dot`, `vij = exp(-(0.5*r2))`, and `fs = 2*vij`; add `qB*vij` to the potential component and `qB*fs*(a.xyz-b.xyz)` to the force components.
- Return `1,000,000,000,000 + round_half_away(1e6 * sum_i((i+1)*(potential_i+force_x_i+force_y_i+force_z_i)))`. The large offset keeps all valid bounded results distinct from the `-1` invalid-input sentinel. Invalid input returns `-1`.

All source variables are binary64 (`fp` is `double`). The independent oracle retains the source loops and arithmetic order. Workload fixtures include exact zero-separation interactions, a nonzero force with `r2=0`, and malformed ranges/framing.

## Pinned source and rights

- Source tree: [`cuda/lavaMD`](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/lavaMD), pinned at commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- Source: [`cuda/lavaMD/kernel/kernel_gpu_cuda.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/lavaMD/kernel/kernel_gpu_cuda.cu), [`cuda/lavaMD/main.h`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/lavaMD/main.h), and [`cuda/lavaMD/main.c`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/lavaMD/main.c), pinned at commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- Pinned launcher: [`cuda/lavaMD/run`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/lavaMD/run) executes `./lavaMD -boxes1d 10`; this package bounds that 10³-box launch profile to one supplied home box and one supplied neighbor box.
- Rodinia attributes the implementation to L. G. Szafaryn, T. Gamblin, B. de Supinski, and K. Skadron, and describes the kernel as derived from ddcMD. The complete University of Virginia notice and citation request are in [`LICENSE.txt`](LICENSE.txt).
- The pinned source's applicable redistribution terms are the included University of Virginia three-condition BSD-style license (BSD-3-Clause compatible). The complete copyright, conditions, warranty disclaimer, and citation request are retained.

## Ports and workload

Implementations are in `c/l`, `c3/l`, `cpp/l`, `elisa/l`, `nim/l`, `odin/l`, `rust/l`, `v/l`, and `zig/l`. The independent oracle is [`benchmarks/rodinia_lavamd_oracle.py`](../../rodinia_lavamd_oracle.py); static fixtures are in [`workload.json`](workload.json).
