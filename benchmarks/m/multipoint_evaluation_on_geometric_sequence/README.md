# Multipoint evaluation on a geometric sequence

Evaluate `f(a*r^i)` for successive `i` using the Bluestein chirp-z identity to turn the values into one polynomial convolution. The primary port computes that bounded convolution with a radix-2 NTT; the independent oracle uses repeated Horner evaluation.

## Contract

- Library Checker operation: [multipoint evaluation on a geometric sequence](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/multipoint_evaluation_on_geometric_sequence/task.md); official limits are recorded in [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/multipoint_evaluation_on_geometric_sequence/info.toml). The task repository is Apache-2.0.
- Packed input is `[N, M, a, r, c_0, ..., c_(N-1)]`, where `c_j` multiplies `x^j`; the result is `f(a*r^i)` for `i=0..M-1` over `998244353`.
- The official task permits `N,M<=524288` and `a,r` in `[0,998244352]`. This local profile uses `1<=N,M<=8`; `a`, `r`, and coefficients are canonical field values in `[0,998244352]`. A zero leading coefficient is allowed.
- For nonzero `a` and `r`, the primary uses `r^(ij) = r^T_(i+j) * r^(-T_i) * r^(-T_j)`, where `T_k=k(k-1)/2`. It reverses the coefficient-side chirp, performs one fixed 32-point NTT convolution, and rescales each result. The fixed transform covers the maximum convolution length for the selected bounds.
- `a=0` is handled as repeated evaluation at zero. `r=0` is handled using the first point `a` followed by repeated zero points. Thus repeated points such as `r=1`, `r=0`, and short cycles remain valid.
- Output is `M` little-endian signed 64-bit values in sequence order. Malformed input returns `-1`; valid input with null or undersized output returns `-2` without writes.
- Maximum packed input is 12 words, maximum output is 64 bytes, and declared working storage is 1024 bytes.

The ten ports are:

- [C](../../../c/m/multipoint_evaluation_on_geometric_sequence.c)
- [C3](../../../c3/m/multipoint_evaluation_on_geometric_sequence.c3)
- [C++](../../../cpp/m/multipoint_evaluation_on_geometric_sequence.cpp)
- [Elisa](../../../elisa/m/multipoint_evaluation_on_geometric_sequence.elisa)
- [Mojo](../../../mojo/m/multipoint_evaluation_on_geometric_sequence.mojo)
- [Nim](../../../nim/m/multipoint_evaluation_on_geometric_sequence.nim)
- [Odin](../../../odin/m/multipoint_evaluation_on_geometric_sequence.odin)
- [Rust](../../../rust/m/multipoint_evaluation_on_geometric_sequence.rs)
- [V](../../../v/m/multipoint_evaluation_on_geometric_sequence.v)
- [Zig](../../../zig/m/multipoint_evaluation_on_geometric_sequence.zig)

The workload is registered with the shared byte-output runner and independent
verifier. The package checker is a static inventory only.

No programs, tests, checkers, builds, compilers, or benchmarks were run while preparing this package.
