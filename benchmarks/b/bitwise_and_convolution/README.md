# Bitwise AND Convolution

This benchmark computes the Library Checker bitwise-AND convolution
([task statement](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/bitwise_and_convolution/task.md),
[official parameters](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/bitwise_and_convolution/info.toml)).
The task definition and algorithm family are the only reused material; the
ports and direct oracle are clean-room implementations.

## Contract

Input is `[N, a_0, ..., a_(2^N-1), b_0, ..., b_(2^N-1)]`. The local bound is
`0 <= N <= 8`; every input coefficient is in `[0, 998244353)`. The official
maximum is `N = 20`. Output is `c_0, ..., c_(2^N-1)`, where
`c_k = sum(a_i * b_j for i, j with (i & j) == k) mod 998244353`, encoded as
little-endian signed 64-bit integers. Invalid input returns `-1`; null output
or insufficient capacity returns `-2` without writing output.

The maximum input has 513 signed 64-bit values and maximum output is 2,048
bytes. Ports use two fixed arrays of 256 coefficients (4,096 bytes total),
reused in place for the transform.

## Algorithm

For each input array, the ports apply the superset zeta transform: for every
bit and mask without that bit, add the value at `mask | bit` into `mask`.
They multiply the transformed arrays pointwise modulo `998244353`, then apply
the inverse superset transform by subtracting the same supersets. The result
at mask `k` is exactly the sum over index pairs whose bitwise AND is `k`.
This takes `O(N * 2^N)` time and `O(2^N)` working space.

The independent Python oracle enumerates all ordered index pairs directly,
using `O(4^N)` work. It does not use either transform. See
[`workload.json`](workload.json) for fixtures and error cases.

## Distinction from related benchmarks

The repository's fast Walsh–Hadamard transform covers XOR convolution. AND
convolution uses a different superset-zeta/Möbius transform and has a
different coefficient operation, so it is a separate benchmark.

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/bitwise_and_convolution.c`](../../../c/b/bitwise_and_convolution.c) |
| C3 | [`c3/b/bitwise_and_convolution.c3`](../../../c3/b/bitwise_and_convolution.c3) |
| C++ | [`cpp/b/bitwise_and_convolution.cpp`](../../../cpp/b/bitwise_and_convolution.cpp) |
| Elisa | [`elisa/b/bitwise_and_convolution.elisa`](../../../elisa/b/bitwise_and_convolution.elisa) |
| Mojo | [`mojo/b/bitwise_and_convolution.mojo`](../../../mojo/b/bitwise_and_convolution.mojo) |
| Nim | [`nim/b/bitwise_and_convolution.nim`](../../../nim/b/bitwise_and_convolution.nim) |
| Odin | [`odin/b/bitwise_and_convolution.odin`](../../../odin/b/bitwise_and_convolution.odin) |
| Rust | [`rust/b/bitwise_and_convolution.rs`](../../../rust/b/bitwise_and_convolution.rs) |
| V | [`v/b/bitwise_and_convolution.v`](../../../v/b/bitwise_and_convolution.v) |
| Zig | [`zig/b/bitwise_and_convolution.zig`](../../../zig/b/bitwise_and_convolution.zig) |
