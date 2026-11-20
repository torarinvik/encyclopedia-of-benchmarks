# Gao Reed–Solomon decoding

Recover a low-degree message polynomial from noisy evaluations over a small
prime field. Gao's decoder interpolates the received word, applies a partial
extended Euclidean algorithm to the interpolation and vanishing polynomials,
then divides the selected remainder by its Bézout coefficient. This polynomial
interpolation and partial-gcd route differs from
[`berlekamp_welch_rs_decode`](../../b/berlekamp_welch_rs_decode/README.md),
which solves a homogeneous numerator/error-locator system. Both are bounded
decoders for Reed–Solomon evaluation words, while
[`misc_reed_solomon`](../../m/misc_reed_solomon/README.md) profiles a shortened
GF(2^8) encoder and syndrome decoder.

## Contract

Input is `[n,k,t,y_0,...,y_(n-1)]`; evaluation points are `x_i=i` in GF(7).
The bounds are `2<=n<=7`, `1<=k<=min(3,n)`, `0<=t<=2`, and `2t<=n-k`, with
received symbols in `0..6`. The decoder interpolates the unique polynomial
`I` of degree less than `n` through the received values and forms
`G(x)=product(x-i)`. It runs extended Euclid on `(G,I)` until the current
nonzero remainder has degree strictly less than `(n+k)/2`, equivalently at
most `(n+k-1)//2`. If that remainder is
`g=uG+vI`, the decoder accepts only when `g` divides exactly by `v`, the
quotient has degree less than `k`, and the quotient's evaluations disagree
with at most `t` received values. A valid input with no such polynomial
returns `0`; malformed input returns `-1`.

The result packs the `k` coefficients in increasing degree order as
`1+c_0+7*c_1+49*c_2`. A zero message polynomial therefore encodes as `1`.
The maximum valid input has 10 i64 values; one extra value is parseable but
invalid. Scratch storage is bounded to 4,096 bytes. With straightforward
polynomial arithmetic, interpolation and the Euclidean phase use `O(n^2)`
field operations; the independent oracle enumerates at most `7^3` candidate
polynomials and counts mismatches directly.

The algorithm follows Shuhong Gao's paper, [“A New Algorithm for Decoding
Reed-Solomon Codes”](https://www.math.clemson.edu/~sgao/papers/RS.pdf), which
describes the interpolation, partial-gcd, and division steps. The benchmark
uses only the algorithmic idea; its finite-field contract, fixtures, oracle,
and ports are independently authored.

| Language | Port |
|---|---|
| C | [c/g/gao_rs_decode.c](../../../c/g/gao_rs_decode.c) |
| C3 | [c3/g/gao_rs_decode.c3](../../../c3/g/gao_rs_decode.c3) |
| C++ | [cpp/g/gao_rs_decode.cpp](../../../cpp/g/gao_rs_decode.cpp) |
| Elisa | [elisa/g/gao_rs_decode.elisa](../../../elisa/g/gao_rs_decode.elisa) |
| Mojo | [mojo/g/gao_rs_decode.mojo](../../../mojo/g/gao_rs_decode.mojo) |
| Nim | [nim/g/gao_rs_decode.nim](../../../nim/g/gao_rs_decode.nim) |
| Odin | [odin/g/gao_rs_decode.odin](../../../odin/g/gao_rs_decode.odin) |
| Rust | [rust/g/gao_rs_decode.rs](../../../rust/g/gao_rs_decode.rs) |
| V | [v/g/gao_rs_decode.v](../../../v/g/gao_rs_decode.v) |
| Zig | [zig/g/gao_rs_decode.zig](../../../zig/g/gao_rs_decode.zig) |
