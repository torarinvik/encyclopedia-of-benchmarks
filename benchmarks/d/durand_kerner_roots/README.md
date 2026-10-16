# Durand–Kerner roots

This benchmark adapts the pinned C and C++ implementations of the
Durand–Kerner simultaneous root iteration. The original examples take command
line coefficients, seed roots from the clock, and print timings. The benchmark
therefore defines a normalized, deterministic variant rather than reproducing
those demonstration details: it fixes the seeds to signed cube roots of unity,
and each iteration computes corrections from the previous root vector before
committing all three estimates together. This avoids the C source's sequential
in-place update order and the C++ OpenMP loop's shared in-place root updates.
The benchmark also replaces the sources' `1e-10` correction/stability stopping
condition and their `INT_MAX` or `INT16_MAX` iteration ceilings with a maximum
correction threshold of `1e-14` and a 100-update cap. The C++ OpenMP path is
not part of this contract because its shared reads and writes do not implement
the deterministic two-phase iteration used here.

## Contract

- The supported polynomial is the bounded cubic `x^3 - d = 0`, where `d` is
  an integer from `-4` through `4`, excluding zero. This bounded family keeps
  all roots distinct and gives reliable convergence from the common seed.
- Input uses the `i64_array_float64` ABI and is packed as
  `[d, root_index, component]`. Root indices `0`, `1`, and `2` follow the
  deterministic seed order; component `0` selects the real part and `1` the
  imaginary part.
- Implementations initialize the three estimates at the signed cube roots of
  unity, update all estimates simultaneously, and stop when the largest
  correction is below `1e-14` or after 100 iterations.
- Malformed arrays, `d` outside the supported nonzero range, an invalid root
  index, or an invalid component return `-1e300`.
- The oracle independently repeats the specified bounded iteration. The
  workload checks every root component for all eight supported constants and
  malformed inputs.

The pinned C implementation is
[`durand_kerner_roots.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/durand_kerner_roots.c).
The pinned C++ implementation is
[`durand_kerner_roots.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/durand_kerner_roots.cpp).
The additional C++ repository contains the same named implementation at
[`durand_kerner_roots.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/durand_kerner_roots.cpp).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/durand_kerner_roots.c`](../../../c/d/durand_kerner_roots.c) |
| C3 | [`c3/d/durand_kerner_roots.c3`](../../../c3/d/durand_kerner_roots.c3) |
| C++ | [`cpp/d/durand_kerner_roots.cpp`](../../../cpp/d/durand_kerner_roots.cpp) |
| Elisa | [`elisa/d/durand_kerner_roots.elisa`](../../../elisa/d/durand_kerner_roots.elisa) |
| Nim | [`nim/d/durand_kerner_roots.nim`](../../../nim/d/durand_kerner_roots.nim) |
| Odin | [`odin/d/durand_kerner_roots.odin`](../../../odin/d/durand_kerner_roots.odin) |
| Rust | [`rust/d/durand_kerner_roots.rs`](../../../rust/d/durand_kerner_roots.rs) |
| V | [`v/d/durand_kerner_roots.v`](../../../v/d/durand_kerner_roots.v) |
| Zig | [`zig/d/durand_kerner_roots.zig`](../../../zig/d/durand_kerner_roots.zig) |

The workload is [`workload.json`](workload.json). Its independent oracle is
[`durand_kerner_roots_oracle.py`](../../durand_kerner_roots_oracle.py).
