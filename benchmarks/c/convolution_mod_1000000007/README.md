# Modular polynomial convolution modulo 1,000,000,007

This package follows the operation and official limits in the [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_mod_1000000007/task.md) and [problem parameters](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_mod_1000000007/info.toml). The task definition is the only reused material; every port and the oracle are clean-room implementations.

## Contract

Input is `[N, M, a_0, ..., a_(N-1), b_0, ..., b_(M-1)]`. The official problem permits each length through 524,288. This bounded profile permits lengths from 1 through 64 and canonical coefficients in `[0, 1,000,000,007)`. It returns the full linear product in degree order:

`c_k = sum(a_i * b_j where i + j = k) mod 1,000,000,007`.

Each coefficient is written as a little-endian signed 64-bit integer. Invalid framing, lengths, or coefficients return `-1`; a null or undersized output returns `-2`. Neither error writes output. The maximum result contains 127 coefficients (1,016 bytes), with a padded transform length of at most 128.

## Algorithm

The target prime 1,000,000,007 does not support the required power-of-two NTT lengths directly. Each port therefore performs three radix-2 NTT convolutions over auxiliary primes 998,244,353, 1,004,535,809, and 469,762,049, all with primitive root 3. Garner reconstruction combines the three residues directly modulo the requested prime.

For any output coefficient, at most 64 products contribute, so its unreduced integer value is no greater than `64 * (1,000,000,006^2)`. That bound is strictly smaller than the product of the three auxiliary primes. The residues therefore identify the exact integer coefficient before reduction modulo 1,000,000,007. The three transforms take `O(L log L)` time for padded length `L`; the documented fixed-array working-storage upper bound is 5,120 bytes.

The [independent Python oracle](../../convolution_mod_1000000007_oracle.py) uses direct nested-loop accumulation with exact Python integers in `O(N*M)` time. It does not use NTT or CRT. The fixtures cover unequal lengths, impulse placement, modular wraparound, zero coefficients, invalid frames and residues, and output-buffer errors.

## Distinction from related benchmarks

The existing [`convolution_mod`](../convolution_mod/README.md) uses the root-friendly target prime 998,244,353 directly. This package benchmarks the different 1,000,000,007 target modulus and its auxiliary-prime NTT plus CRT reconstruction. [`convolution_mod_2_64`](../convolution_mod_2_64/README.md) computes in the unsigned wraparound ring modulo `2^64`, which has a different coefficient domain and result semantics.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convolution_mod_1000000007.c`](../../../c/c/convolution_mod_1000000007.c) |
| C3 | [`c3/c/convolution_mod_1000000007.c3`](../../../c3/c/convolution_mod_1000000007.c3) |
| C++ | [`cpp/c/convolution_mod_1000000007.cpp`](../../../cpp/c/convolution_mod_1000000007.cpp) |
| Elisa | [`elisa/c/convolution_mod_1000000007.elisa`](../../../elisa/c/convolution_mod_1000000007.elisa) |
| Mojo | [`mojo/c/convolution_mod_1000000007.mojo`](../../../mojo/c/convolution_mod_1000000007.mojo) |
| Nim | [`nim/c/convolution_mod_1000000007.nim`](../../../nim/c/convolution_mod_1000000007.nim) |
| Odin | [`odin/c/convolution_mod_1000000007.odin`](../../../odin/c/convolution_mod_1000000007.odin) |
| Rust | [`rust/c/convolution_mod_1000000007.rs`](../../../rust/c/convolution_mod_1000000007.rs) |
| V | [`v/c/convolution_mod_1000000007.v`](../../../v/c/convolution_mod_1000000007.v) |
| Zig | [`zig/c/convolution_mod_1000000007.zig`](../../../zig/c/convolution_mod_1000000007.zig) |
