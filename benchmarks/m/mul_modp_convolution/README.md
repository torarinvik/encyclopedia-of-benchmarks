# Multiplicative convolution modulo a prime

This package implements Library Checker `mul_modp_convolution`:

`c[k] = sum(a[i] * b[j]) mod 998244353` over residue pairs whose product is
`i*j == k (mod P)`, where `P` is prime.

The bounded profile uses `2<=P<=97`. For nonzero residues, each port finds a
primitive root `g`, maps residue `g^e` to exponent `e` in the cyclic group of
order `P-1`, computes a cyclic convolution of those exponent-indexed arrays,
and maps the result back to residues. Residue zero is handled separately:
`c[0] = b[0]*sum(a) + a[0]*sum(b[1..]) (mod MOD)`, which counts each pair with
zero product exactly once. The bounded cyclic convolution is O(P²); this
profile makes no large-P transform claim. The independent verifier directly
enumerates all residue pairs.

## ABI

The symbol is `mul_modp_convolution`, using `i64_array_bytes_output`. Input is
`[P,a[0..P),b[0..P)]`. `P` must be prime and in `[2,97]`; coefficients are in
`[0,998244352]`. Invalid input returns `-1` before output checks. For valid
input, null output or capacity below `8*P` returns `-2` without writes.
Success writes `P` little-endian signed 64-bit coefficients. Maximum valid
input length is 195 words, parseable limit 196, output maximum 776 bytes.

## Source and rights

The operation and limits are from the Apache-2.0 licensed Library Checker
repository: [task](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/mul_modp_convolution/task.md),
[limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/mul_modp_convolution/info.toml),
[repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE).
The task contract is used as source; local implementations and the bounded
primitive-root/exponent method are clean-room. See [RIGHTS.md](RIGHTS.md).

Workload fixtures are in [workload.json](workload.json). Primary and
independent oracles are
[`mul_modp_convolution_oracle.py`](../../mul_modp_convolution_oracle.py)
and
[`mul_modp_convolution_verifier_oracle.py`](../../mul_modp_convolution_verifier_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/mul_modp_convolution.c`](../../../c/m/mul_modp_convolution.c) |
| C3 | [`c3/m/mul_modp_convolution.c3`](../../../c3/m/mul_modp_convolution.c3) |
| C++ | [`cpp/m/mul_modp_convolution.cpp`](../../../cpp/m/mul_modp_convolution.cpp) |
| Elisa | [`elisa/m/mul_modp_convolution.elisa`](../../../elisa/m/mul_modp_convolution.elisa) |
| Mojo | [`mojo/m/mul_modp_convolution.mojo`](../../../mojo/m/mul_modp_convolution.mojo) |
| Nim | [`nim/m/mul_modp_convolution.nim`](../../../nim/m/mul_modp_convolution.nim) |
| Odin | [`odin/m/mul_modp_convolution.odin`](../../../odin/m/mul_modp_convolution.odin) |
| Rust | [`rust/m/mul_modp_convolution.rs`](../../../rust/m/mul_modp_convolution.rs) |
| V | [`v/m/mul_modp_convolution.v`](../../../v/m/mul_modp_convolution.v) |
| Zig | [`zig/m/mul_modp_convolution.zig`](../../../zig/m/mul_modp_convolution.zig) |
