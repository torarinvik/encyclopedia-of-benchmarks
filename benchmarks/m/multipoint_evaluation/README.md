# Multipoint polynomial evaluation

Evaluate one polynomial at several points using a product tree for the linear factors and a remainder tree to distribute the polynomial remainders. The independent oracle evaluates each point separately with Horner’s rule.

## Contract

- Library Checker operation: [multipoint evaluation](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/multipoint_evaluation/task.md); its limits are recorded at [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/multipoint_evaluation/info.toml). The task repository is Apache-2.0.
- Packed input is `[N, M, c_0, ..., c_(N-1), p_0, ..., p_(M-1)]`, with coefficients and points in ascending monomial order over `998244353`.
- The local bounds are `1 <= N,M <= 8`; coefficients and points are in `[0, 998244352]`; the leading polynomial coefficient must be nonzero.
- The result contains `M` values in point order, encoded as little-endian signed 64-bit integers. Malformed input returns `-1`; valid input with a null or undersized output buffer returns `-2` without writes.
- The primary implementation builds monic products `(x-p_i)` bottom-up and propagates remainders top-down. Naive polynomial multiplication and division keep this small profile bounded; the tree supports repeated points and non-power-of-two point counts.
- The maximum packed input length is 18 words, maximum output is 64 bytes, and declared local workspace is 4096 bytes.

The ten ports are:

- [C](../../../c/m/multipoint_evaluation.c)
- [C3](../../../c3/m/multipoint_evaluation.c3)
- [C++](../../../cpp/m/multipoint_evaluation.cpp)
- [Elisa](../../../elisa/m/multipoint_evaluation.elisa)
- [Mojo](../../../mojo/m/multipoint_evaluation.mojo)
- [Nim](../../../nim/m/multipoint_evaluation.nim)
- [Odin](../../../odin/m/multipoint_evaluation.odin)
- [Rust](../../../rust/m/multipoint_evaluation.rs)
- [V](../../../v/m/multipoint_evaluation.v)
- [Zig](../../../zig/m/multipoint_evaluation.zig)

The workload is registered with the shared byte-output runner and independent
verifier. The package checker is a static inventory only.

No programs, tests, checkers, builds, or benchmarks were run while preparing this package.
