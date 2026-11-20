# Barrett modular reduction

This benchmark reduces a batch of nonnegative integers modulo one supplied
modulus by using a precomputed reciprocal scaled by `2^32`. It measures the
reciprocal quotient estimate and bounded correction in Barrett reduction.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is `barrett_reduction`.
Input is `[m,q,x[0],...,x[q-1]]`, with `2 <= m <= 65535`, `0 <= q <= 12`,
`0 <= x[i] < m^2`, and exact length `2+q`. The modulus reciprocal is
`mu=floor(2^32/m)`, computed once per call. For each input value, the port
computes `qhat=floor(x*mu/2^32)`, forms `r=x-qhat*m`, and subtracts `m` once
when `r>=m`. The result is
`sum((i+1)*(r[i]+1))`, with zero-based `i`. A valid empty batch returns zero.
Null, out-of-range, or malformed input returns `-1`. Maximum valid and
parseable lengths are 14 and 15 words.

Since `mu <= 2^32/m`, `qhat` never exceeds `floor(x/m)`. The quotient
underestimate is less than `x/2^32 < 1` because `x<m^2` and `m<=65535`; thus
the preliminary residual is nonnegative and less than `2m`, so one correction
is sufficient. Also `x*mu < m*2^32 < 2^48`, keeping every product safely inside
signed 64-bit arithmetic. The checksum is at most
`(1+...+12)*65535 = 5,111,730`.

This profile differs from local [`embench_aha_mont64`](../../a/embench_aha_mont64/README.md),
which uses Montgomery REDC with a fixed `2^64` radix and requires an odd
modulus; this package uses a floor reciprocal and supports every modulus in
its bounded domain. The independent oracle uses direct `%` for each input,
while the primary oracle uses the reciprocal estimate and correction.

## Provenance

The reciprocal-reduction idea follows Paul Barrett, “Implementing the Rivest
Shamir and Adleman Public Key Encryption Algorithm on a Standard Digital
Signal Processor,” *Advances in Cryptology — CRYPTO ’86*, Lecture Notes in
Computer Science 263, 311–323 (1987), [paper copy](https://www.loper-os.org/pub/barrett_1986.pdf),
[DOI](https://doi.org/10.1007/3-540-47721-7_24). The original long-modulus
routine estimates the quotient using a scaled reciprocal and corrects the
remainder. This benchmark uses a bounded single-word specialization with
explicit proof bounds. The ports implement the mathematical method only; no
source code or prose is copied. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/b/barrett_reduction.c](../../../c/b/barrett_reduction.c) |
| C3 | [c3/b/barrett_reduction.c3](../../../c3/b/barrett_reduction.c3) |
| C++ | [cpp/b/barrett_reduction.cpp](../../../cpp/b/barrett_reduction.cpp) |
| Elisa | [elisa/b/barrett_reduction.elisa](../../../elisa/b/barrett_reduction.elisa) |
| Mojo | [mojo/b/barrett_reduction.mojo](../../../mojo/b/barrett_reduction.mojo) |
| Nim | [nim/b/barrett_reduction.nim](../../../nim/b/barrett_reduction.nim) |
| Odin | [odin/b/barrett_reduction.odin](../../../odin/b/barrett_reduction.odin) |
| Rust | [rust/b/barrett_reduction.rs](../../../rust/b/barrett_reduction.rs) |
| V | [v/b/barrett_reduction.v](../../../v/b/barrett_reduction.v) |
| Zig | [zig/b/barrett_reduction.zig](../../../zig/b/barrett_reduction.zig) |

Fixtures cover empty and mixed batches, a case requiring the one-subtraction
correction, the maximum frame, malformed values, and null input.
