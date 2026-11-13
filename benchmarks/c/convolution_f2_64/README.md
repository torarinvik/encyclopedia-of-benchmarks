# Convolution over GF(2^64)

Compute a linear convolution whose coefficients are elements of the finite
field `GF(2^64) = GF(2)[x]/(x^64+x^4+x^3+x+1)`. Each field element is stored
as the 64-bit coefficient mask of a polynomial of degree below 64. Addition is
bitwise XOR; multiplication is carryless polynomial multiplication followed
by reduction modulo the irreducible degree-64 polynomial.

## Contract

The exported symbol is `convolution_f2_64`, using the
`i64_array_bytes_output` ABI. Input is `[N,M,a_0,...,a_(N-1),b_0,...,b_(M-1)]`,
with `1<=N,M<=8`. Every signed i64 bit pattern is reinterpreted as an
unsigned 64-bit field element. Output contains `N+M-1` coefficients in
increasing degree order, each encoded as eight little-endian bytes. Invalid
input returns `-1`; a null output or capacity below `8*(N+M-1)` returns `-2`
without writing. Maximum valid/parseable input lengths are 18/19 i64 words,
maximum output is 120 bytes, and the workspace reservation is 512 bytes.

## Algorithms

The primary multiplies two field elements with a 64-step shift-and-reduce
loop. It accumulates each pairwise coefficient product into its convolution
index with XOR. Its time is `O(64*N*M)` and auxiliary space is `O(N+M)`.
The independent oracle first forms each unreduced carryless product as an
integer polynomial, then performs high-degree polynomial long division by the
fixed modulus before accumulating output coefficients. Its time is
`O(128*N*M)` and space is `O(N+M)`.

This package is materially distinct from [`convolution_mod_2_64`](../convolution_mod_2_64/README.md),
which computes in the integer ring modulo `2^64`, and from
[`nim_product_64`](../../n/nim_product_64/README.md), which uses nimber
multiplication. The official task permits lengths through 524,288; this
bounded profile is intended to benchmark the field arithmetic and convolution
kernel on small, varied inputs.

The source task is [Library Checker Convolution over `GF(2^64)`](https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_F_2_64/task.md),
with [official bounds](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/convolution/convolution_F_2_64/info.toml).
The repository license is Apache-2.0; this package uses the mathematical
contract only. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json),
the two oracle modules, and the static checker
[`check_convolution_f2_64_package.py`](../../check_convolution_f2_64_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/convolution_f2_64.c`](../../../c/c/convolution_f2_64.c) |
| C3 | [`c3/c/convolution_f2_64.c3`](../../../c3/c/convolution_f2_64.c3) |
| C++ | [`cpp/c/convolution_f2_64.cpp`](../../../cpp/c/convolution_f2_64.cpp) |
| Elisa | [`elisa/c/convolution_f2_64.elisa`](../../../elisa/c/convolution_f2_64.elisa) |
| Mojo | [`mojo/c/convolution_f2_64.mojo`](../../../mojo/c/convolution_f2_64.mojo) |
| Nim | [`nim/c/convolution_f2_64.nim`](../../../nim/c/convolution_f2_64.nim) |
| Odin | [`odin/c/convolution_f2_64.odin`](../../../odin/c/convolution_f2_64.odin) |
| Rust | [`rust/c/convolution_f2_64.rs`](../../../rust/c/convolution_f2_64.rs) |
| V | [`v/c/convolution_f2_64.v`](../../../v/c/convolution_f2_64.v) |
| Zig | [`zig/c/convolution_f2_64.zig`](../../../zig/c/convolution_f2_64.zig) |
