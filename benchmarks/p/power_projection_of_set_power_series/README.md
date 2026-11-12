# Power Projection of a Set Power Series

This package computes weighted projections of successive powers of a set
power series in the square-zero algebra over F_998244353. It returns
`sum_i w_i [x^i] s(x)^m` for every `m` from zero through `M-1`.

## Bounded contract

The `i64_array_bytes_output` input is `[N, M, a_0, ..., a_(2^N-1),
w_0, ..., w_(2^N-1)]`, with masks in increasing integer order, `0<=N<=4`,
`0<=M<=8`, and all coefficients and weights in `[0,998244352]`. The result
contains M little-endian signed 64-bit residues, one per power, and returns
`8*M` bytes. For `M=0`, the valid output is empty and success returns zero.
Malformed input returns `-1`; a null output or capacity below the exact output
size returns `-2` without writes. The maximum valid input is 34 words, the
maximum parseable input is 35 words, the maximum output is 64 bytes, and
workspace is bounded at 512 bytes.

## Algorithms

The ports start with the multiplicative identity and multiply by `s` between
successive projections. Square-zero subset convolution computes
`(u*v)[S] = sum(T subset S) u[T]v[S\T]` by enumerating submasks, in
`O(3^N)` time per multiplication and `O(2^N)` storage. The total running
time is `O(M*3^N + M*2^N)` for the bounded profile.

The independent oracle enumerates each variable’s assignment to no factor or
to one of the ordered factors of `s^m`. This directly constructs each
coefficient contribution before applying the weights; it does not call the
subset-convolution routine.

This operation is distinct from [`fast_subset_convolution`](../../f/fast_subset_convolution/README.md),
which multiplies two set functions but does not return weighted projections
for successive powers.

## Provenance and rights

The operation and square-zero algebra come from Library Checker’s
[Power Projection of Set Power Series task](https://github.com/yosupo06/library-checker-problems/blob/master/set_power_series/power_projection_of_set_power_series/task.md)
and [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/set_power_series/power_projection_of_set_power_series/info.toml).
The local workload and ports are clean-room; see [RIGHTS.md](RIGHTS.md).
`workload.json` contains named fixtures and ABI bounds, and
`verify_workload.py` statically inventories the package. The workload is
registered with the shared byte-output runner and independent verifier.

| Language | Source |
|---|---|
| C | [`c/power_projection_of_set_power_series.c`](../../../c/power_projection_of_set_power_series.c) |
| C3 | [`c3/power_projection_of_set_power_series.c3`](../../../c3/power_projection_of_set_power_series.c3) |
| C++ | [`cpp/power_projection_of_set_power_series.cpp`](../../../cpp/power_projection_of_set_power_series.cpp) |
| Elisa | [`elisa/power_projection_of_set_power_series.elisa`](../../../elisa/power_projection_of_set_power_series.elisa) |
| Mojo | [`mojo/power_projection_of_set_power_series.mojo`](../../../mojo/power_projection_of_set_power_series.mojo) |
| Nim | [`nim/power_projection_of_set_power_series.nim`](../../../nim/power_projection_of_set_power_series.nim) |
| Odin | [`odin/power_projection_of_set_power_series.odin`](../../../odin/power_projection_of_set_power_series.odin) |
| Rust | [`rust/power_projection_of_set_power_series.rs`](../../../rust/power_projection_of_set_power_series.rs) |
| V | [`v/power_projection_of_set_power_series.v`](../../../v/power_projection_of_set_power_series.v) |
| Zig | [`zig/power_projection_of_set_power_series.zig`](../../../zig/power_projection_of_set_power_series.zig) |
