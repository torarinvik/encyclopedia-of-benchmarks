# Shift of Sampling Points of a Polynomial

Given samples `f(0), f(1), ..., f(N-1)` of a polynomial of degree less than
`N` over `F_998244353`, this package returns `f(c), f(c+1), ..., f(c+M-1)`.
This changes the sampling locations while preserving the represented
polynomial; it does not shift the polynomial’s coefficient basis.

## Bounded contract

The `i64_array_bytes_output` input is `[N, M, c, f(0), ..., f(N-1)]`, with
`1<=N<=16`, `1<=M<=16`, and `c` plus all sample values in
`[0,998244352]`. The sample points `0..N-1` are distinct in the field. The
output is M little-endian signed 64-bit residues in point order and success
returns `8*M` bytes. Malformed input returns `-1`; a null output or a capacity
below `8*M` returns `-2` without writes. The maximum valid input has 19 words;
the maximum parseable input is 20 words. Maximum output is 128 bytes and
workspace is at most 512 bytes.

## Algorithm

The primary ports build forward differences in place and use
`f(x)=sum_k (Delta^k f(0)/k!) * x(x-1)...(x-k+1)`. They evaluate this Newton
falling-factorial expansion at each requested point. The work is
`O(N^2 + N*M + log(MOD))`, with `O(N)` auxiliary storage. The independent
oracle evaluates the direct Lagrange interpolation basis at every requested
point, with `O(N^2*M)` work. This package is distinct from
[`polynomial_taylor_shift`](../polynomial_taylor_shift/README.md), which
transforms a supplied coefficient vector for `f(x+c)` rather than shifting a
list of sample locations.

## Source and rights

The official operation and constraints are in Library Checker’s
[task statement](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/shift_of_sampling_points_of_polynomial/task.md)
and [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/shift_of_sampling_points_of_polynomial/info.toml).
The upstream repository is Apache-2.0. The bounded profile and all local
materials are clean-room; see [RIGHTS.md](RIGHTS.md).

[`workload.json`](workload.json) records fixtures and ABI bounds.
[`verify_workload.py`](verify_workload.py) statically checks fixture/oracle
agreement, provenance, and all ten port paths. It does not launch ports.
Shared suite registration is complete in the `i64_array_bytes_output` runner
and verifier. No programs, tests, checkers, builds, compilers, or benchmarks
were run during integration.

| Language | Source |
|---|---|
| C | [c/s/shift_of_sampling_points_of_polynomial.c](../../../c/s/shift_of_sampling_points_of_polynomial.c) |
| C3 | [c3/s/shift_of_sampling_points_of_polynomial.c3](../../../c3/s/shift_of_sampling_points_of_polynomial.c3) |
| C++ | [cpp/s/shift_of_sampling_points_of_polynomial.cpp](../../../cpp/s/shift_of_sampling_points_of_polynomial.cpp) |
| Elisa | [elisa/s/shift_of_sampling_points_of_polynomial.elisa](../../../elisa/s/shift_of_sampling_points_of_polynomial.elisa) |
| Mojo | [mojo/s/shift_of_sampling_points_of_polynomial.mojo](../../../mojo/s/shift_of_sampling_points_of_polynomial.mojo) |
| Nim | [nim/s/shift_of_sampling_points_of_polynomial.nim](../../../nim/s/shift_of_sampling_points_of_polynomial.nim) |
| Odin | [odin/s/shift_of_sampling_points_of_polynomial.odin](../../../odin/s/shift_of_sampling_points_of_polynomial.odin) |
| Rust | [rust/s/shift_of_sampling_points_of_polynomial.rs](../../../rust/s/shift_of_sampling_points_of_polynomial.rs) |
| V | [v/s/shift_of_sampling_points_of_polynomial.v](../../../v/s/shift_of_sampling_points_of_polynomial.v) |
| Zig | [zig/s/shift_of_sampling_points_of_polynomial.zig](../../../zig/s/shift_of_sampling_points_of_polynomial.zig) |
