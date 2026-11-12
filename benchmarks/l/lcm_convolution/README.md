# LCM convolution

This benchmark implements the [Library Checker LCM Convolution task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/lcm_convolution/task.md), using its [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/lcm_convolution/info.toml) and published multiple-zeta/Möbius method as an algorithm reference. The ports and direct oracle are clean-room implementations.

## Contract

Input is `[N, a_1, ..., a_N, b_1, ..., b_N]`, with `1 <= N <= 128` and coefficients in `[0, 998244353)`. The official task permits `N <= 1,000,000`; this smaller local bound keeps the direct quadratic oracle and fixed workspace practical. Output is `c_1, ..., c_N`, encoded as little-endian signed 64-bit integers, where

`c_k = sum(a_i * b_j for lcm(i, j) == k) mod 998244353`.

Invalid input returns `-1`. A null output or output capacity below `8*N` returns `-2` without writing bytes. The maximum valid and parseable input lengths are 257 and 258 values; maximum output is 1,024 bytes.

## Algorithm and distinctness

The multiple-zeta transform visits each divisor `d` in descending order and adds its value into every multiple. The pointwise product of the two transformed arrays is inverted by ascending-order Möbius subtraction, yielding the exact-LCM convolution. This uses `O(N log N)` time and `O(N)` workspace. The transform directions and output grouping are dual to GCD convolution, so the pair-index operation and measured traversal differ even though both use divisor-lattice transforms.

The independent oracle directly enumerates all `N^2` ordered index pairs, computes each LCM, and accumulates products when that LCM is at most `N`. A scalar LCM sum, divisor enumeration, divisor sums, ordinary convolution, and GCD convolution do not return this exact-LCM pair grouping.

[`workload.json`](workload.json) contains hand-checkable outputs and malformed input/output cases. The verifier also generates bounded deterministic cases through the local maximum `N`.

## Language ports

| Language | Source |
|---|---|
| C | [`c/l/lcm_convolution.c`](../../../c/l/lcm_convolution.c) |
| C3 | [`c3/l/lcm_convolution.c3`](../../../c3/l/lcm_convolution.c3) |
| C++ | [`cpp/l/lcm_convolution.cpp`](../../../cpp/l/lcm_convolution.cpp) |
| Elisa | [`elisa/l/lcm_convolution.elisa`](../../../elisa/l/lcm_convolution.elisa) |
| Mojo | [`mojo/l/lcm_convolution.mojo`](../../../mojo/l/lcm_convolution.mojo) |
| Nim | [`nim/l/lcm_convolution.nim`](../../../nim/l/lcm_convolution.nim) |
| Odin | [`odin/l/lcm_convolution.odin`](../../../odin/l/lcm_convolution.odin) |
| Rust | [`rust/l/lcm_convolution.rs`](../../../rust/l/lcm_convolution.rs) |
| V | [`v/l/lcm_convolution.v`](../../../v/l/lcm_convolution.v) |
| Zig | [`zig/l/lcm_convolution.zig`](../../../zig/l/lcm_convolution.zig) |
