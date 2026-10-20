# Number theoretic transform

This package implements the forward radix-2 number theoretic transform (NTT)
for the fixed AtCoder Library modulus `998244353`. It returns the natural-order
discrete transform of one coefficient vector. It does not implement inverse
transforms or polynomial convolution.

## Contract

The exported `number_theoretic_transform` entry point uses the
`i64_array_bytes_output` ABI. Input is `[n, a[0], ..., a[n-1]]`, where `n` is a
power of two from 1 through 64 and every coefficient is a canonical residue in
`0..998244352`. The primitive root is 3 and `omega = 3^((998244353-1)/n)`.
Output coefficient `k` is `sum(a[j] * omega^(j*k)) mod 998244353`; coefficients
are in natural index order and encoded as unsigned 32-bit little-endian words.
The output is exactly `4*n` bytes (maximum 256). Invalid input returns `-1`
before checking output storage. Null output or capacity below `4*n` returns
`-2` without writing. Success returns `4*n`.

The ports use an iterative radix-2 transform. The independent
[`number_theoretic_transform_oracle.py`](../../number_theoretic_transform_oracle.py)
uses the direct O(n²) modular DFT, rather than the ports' butterfly stages.
[`workload.json`](workload.json) defines the bounded cases.

## Pinned source and license

This contract is based on AtCoder Library's convolution implementation and
its default modulus. The source is pinned to
[AtCoder `convolution.hpp`](https://github.com/atcoder/ac-library/blob/864245a00b00dd008d1abfdc239618fdb7d139da/atcoder/convolution.hpp)
and [convolution documentation](https://github.com/atcoder/ac-library/blob/864245a00b00dd008d1abfdc239618fdb7d139da/document_en/convolution.md)
at commit `864245a00b00dd008d1abfdc239618fdb7d139da`. The bounded ports are
new implementations of the documented forward transform, not copied source.
AtCoder Library is CC0 1.0 Universal; the complete notice is in
[`LICENSE.txt`](LICENSE.txt).

## Ports

| Language | Port |
|---|---|
| C | [`c/n/number_theoretic_transform.c`](../../../c/n/number_theoretic_transform.c) |
| C3 | [`c3/n/number_theoretic_transform.c3`](../../../c3/n/number_theoretic_transform.c3) |
| C++ | [`cpp/n/number_theoretic_transform.cpp`](../../../cpp/n/number_theoretic_transform.cpp) |
| Elisa | [`elisa/n/number_theoretic_transform.elisa`](../../../elisa/n/number_theoretic_transform.elisa) |
| Nim | [`nim/n/number_theoretic_transform.nim`](../../../nim/n/number_theoretic_transform.nim) |
| Odin | [`odin/n/number_theoretic_transform.odin`](../../../odin/n/number_theoretic_transform.odin) |
| Rust | [`rust/n/number_theoretic_transform.rs`](../../../rust/n/number_theoretic_transform.rs) |
| V | [`v/n/number_theoretic_transform.v`](../../../v/n/number_theoretic_transform.v) |
| Zig | [`zig/n/number_theoretic_transform.zig`](../../../zig/n/number_theoretic_transform.zig) |
