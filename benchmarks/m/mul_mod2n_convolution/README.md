# Multiplicative convolution modulo a power of two

This package implements Library Checker `mul_mod2n_convolution`:

`c[k] = sum(a[i] * b[j]) mod 998244353` over residue pairs satisfying
`i*j == k (mod 2^N)`. Unlike the prime-modulus multiplicative group, the
residue ring modulo `2^N` has zero divisors, so this is a separate operation
and package.

The bounded profile accepts `0 <= N <= 5`, hence at most 32 residues. Each
port directly enumerates every pair `(i,j)`, adds its coefficient product to
`c[(i*j) mod 2^N]`, and reduces the coefficient sum modulo 998244353. The
profile is O(4^N), bounded to at most 1024 pair visits. It makes no claim to
the large-N algorithms used for the full task.

## ABI

The symbol is `mul_mod2n_convolution`, using `i64_array_bytes_output`. Input
is `[N,a[0..2^N),b[0..2^N)]`, with coefficients in `[0,998244352]`. Malformed
input returns `-1` before output checks. Valid input with null output or
capacity below `8*2^N` returns `-2` without writes. Success writes `2^N`
little-endian signed 64-bit coefficients. Maximum valid input length is 65
words, parseable limit is 66, and maximum output/workspace buffer is 256 bytes.

## Source and rights

The operation and coefficient modulus come from the Apache-2.0 licensed
Library Checker repository: [task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/mul_mod2n_convolution/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/mul_mod2n_convolution/info.toml),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The bounded direct implementation is clean-room. See [RIGHTS.md](RIGHTS.md).

Workload fixtures are in [workload.json](workload.json). The primary and
independent oracles are
[`mul_mod2n_convolution_oracle.py`](../../mul_mod2n_convolution_oracle.py)
and
[`mul_mod2n_convolution_verifier_oracle.py`](../../mul_mod2n_convolution_verifier_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/mul_mod2n_convolution.c`](../../../c/m/mul_mod2n_convolution.c) |
| C3 | [`c3/m/mul_mod2n_convolution.c3`](../../../c3/m/mul_mod2n_convolution.c3) |
| C++ | [`cpp/m/mul_mod2n_convolution.cpp`](../../../cpp/m/mul_mod2n_convolution.cpp) |
| Elisa | [`elisa/m/mul_mod2n_convolution.elisa`](../../../elisa/m/mul_mod2n_convolution.elisa) |
| Mojo | [`mojo/m/mul_mod2n_convolution.mojo`](../../../mojo/m/mul_mod2n_convolution.mojo) |
| Nim | [`nim/m/mul_mod2n_convolution.nim`](../../../nim/m/mul_mod2n_convolution.nim) |
| Odin | [`odin/m/mul_mod2n_convolution.odin`](../../../odin/m/mul_mod2n_convolution.odin) |
| Rust | [`rust/m/mul_mod2n_convolution.rs`](../../../rust/m/mul_mod2n_convolution.rs) |
| V | [`v/m/mul_mod2n_convolution.v`](../../../v/m/mul_mod2n_convolution.v) |
| Zig | [`zig/m/mul_mod2n_convolution.zig`](../../../zig/m/mul_mod2n_convolution.zig) |
