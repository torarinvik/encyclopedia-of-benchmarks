# Bitwise OR convolution

This package computes

`c[k] = sum(a[i] * b[j] for i | j == k) mod 998244353`.

It is the OR/union product on the subset lattice. The clean-room ports apply
subset zeta transforms to both inputs, multiply corresponding entries, and
apply subset Möbius inversion in `O(N * 2^N)` time and `O(2^N)` workspace.
The local bound is `0 <= N <= 8`, with vectors of length `2^N`; the
implementation is a bounded profile, not a claim about the scale or
performance of an external task.

## ABI

Symbol: `bitwise_or_convolution`; ABI: `i64_array_bytes_output`. Input is
`[N, a[0..2^N), b[0..2^N)]`. Coefficients are residues in
`[0,998244353)`. Malformed input returns `-1` before output checks. Valid
input with null output or capacity below `8*2^N` returns `-2` without writes.
Success writes one little-endian signed 64-bit residue per index. The maximum
input is 513 words; output is at most 2048 bytes.

The primary oracle directly enumerates input pairs. The independent verifier
computes each output coordinate by a separate target-index scan. The workload
contains small exact fixtures; the package checker also documents the maximum
all-ones result `3^popcount(k) mod 998244353`.

## Provenance and rights

The OR-convolution / subset-lattice transform identity is described in
[Neel Mishra's convolution variants note](https://neelmishra.github.io/blog/cp/algebra/convolution-variants.html).
This package is not a Library Checker task and makes no such provenance claim.
Ports and oracles are independently written from the stated operation; no
source code or prose is copied. See
[RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

## Ports

| Language | Source |
|---|---|
| C | [`c/b/bitwise_or_convolution.c`](../../../c/b/bitwise_or_convolution.c) |
| C3 | [`c3/b/bitwise_or_convolution.c3`](../../../c3/b/bitwise_or_convolution.c3) |
| C++ | [`cpp/b/bitwise_or_convolution.cpp`](../../../cpp/b/bitwise_or_convolution.cpp) |
| Elisa | [`elisa/b/bitwise_or_convolution.elisa`](../../../elisa/b/bitwise_or_convolution.elisa) |
| Mojo | [`mojo/b/bitwise_or_convolution.mojo`](../../../mojo/b/bitwise_or_convolution.mojo) |
| Nim | [`nim/b/bitwise_or_convolution.nim`](../../../nim/b/bitwise_or_convolution.nim) |
| Odin | [`odin/b/bitwise_or_convolution.odin`](../../../odin/b/bitwise_or_convolution.odin) |
| Rust | [`rust/b/bitwise_or_convolution.rs`](../../../rust/b/bitwise_or_convolution.rs) |
| V | [`v/b/bitwise_or_convolution.v`](../../../v/b/bitwise_or_convolution.v) |
| Zig | [`zig/b/bitwise_or_convolution.zig`](../../../zig/b/bitwise_or_convolution.zig) |
