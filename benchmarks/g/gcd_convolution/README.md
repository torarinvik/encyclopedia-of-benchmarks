# GCD convolution

This benchmark implements the [Library Checker GCD Convolution task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/gcd_convolution/task.md), using its [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/gcd_convolution/info.toml) and the published divisor-zeta/Möbius method as an algorithm reference. The local ports and direct oracle are clean-room implementations.

## Contract

Input is `[N, a_1, ..., a_N, b_1, ..., b_N]`, with `1 <= N <= 128` and coefficients in `[0, 998244353)`. The official task permits `N <= 1,000,000`; the smaller local bound keeps the direct quadratic oracle and fixed workspace practical. Output is `c_1, ..., c_N`, encoded as little-endian signed 64-bit integers, where

`c_k = sum(a_i * b_j for gcd(i, j) == k) mod 998244353`.

Invalid input returns `-1`. A null output or output capacity below `8*N` returns `-2` without writing bytes. The maximum valid and parseable input lengths are 257 and 258 values; maximum output is 1,024 bytes.

## Algorithm and distinctness

For each divisor `d`, the divisor-zeta transform replaces `a_d` by the sum of all `a_m` for multiples `m` of `d`; it does the same for `b`. The pointwise product of transformed values is inverted with the reverse-order Möbius transform, yielding the exact-GCD convolution. The transforms take `O(N log N)` time and `O(N)` workspace.

The independent oracle directly enumerates all `N^2` ordered index pairs and groups each product by `gcd(i,j)`. Ordinary GCD, Möbius values, divisor enumeration, divisor sums, and ordinary polynomial convolution do not compute this pair-indexed convolution, so this profile remains distinct.

[`workload.json`](workload.json) includes small hand-checkable outputs and malformed input/output cases. The verifier also supplies bounded deterministic cases through the local maximum `N`.

## Language ports

| Language | Source |
|---|---|
| C | [`c/g/gcd_convolution.c`](../../../c/g/gcd_convolution.c) |
| C3 | [`c3/g/gcd_convolution.c3`](../../../c3/g/gcd_convolution.c3) |
| C++ | [`cpp/g/gcd_convolution.cpp`](../../../cpp/g/gcd_convolution.cpp) |
| Elisa | [`elisa/g/gcd_convolution.elisa`](../../../elisa/g/gcd_convolution.elisa) |
| Mojo | [`mojo/g/gcd_convolution.mojo`](../../../mojo/g/gcd_convolution.mojo) |
| Nim | [`nim/g/gcd_convolution.nim`](../../../nim/g/gcd_convolution.nim) |
| Odin | [`odin/g/gcd_convolution.odin`](../../../odin/g/gcd_convolution.odin) |
| Rust | [`rust/g/gcd_convolution.rs`](../../../rust/g/gcd_convolution.rs) |
| V | [`v/g/gcd_convolution.v`](../../../v/g/gcd_convolution.v) |
| Zig | [`zig/g/gcd_convolution.zig`](../../../zig/g/gcd_convolution.zig) |
