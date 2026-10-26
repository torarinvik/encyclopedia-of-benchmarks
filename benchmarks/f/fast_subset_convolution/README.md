# Fast subset convolution

This package benchmarks the rank-based fast subset convolution described in the “Fast Subset Convolution” chapter of *Encyclopedia of Algorithms* (DOI [10.1007/978-1-4939-2864-4_518](https://doi.org/10.1007/978-1-4939-2864-4_518)). It is a clean independent implementation; no book code, prose, or figures are reproduced.

Given two functions `f` and `g` on subsets of an `n`-element universe, the result is `h[S] = sum(f[A] * g[S\A] for A subset of S) mod P`, with `P=998244353`. The implementation uses ranked subset zeta transforms, rank-wise multiplication, Möbius inversion, and the rank `popcount(S)` coefficient. This is distinct from ordinary subset-sum and from convolution over integer-indexed sequences.

## Contract

The `i64_array_bytes_output` input is `[n, f[0..2^n), g[0..2^n)]`, with `0 <= n <= 4` and every coefficient in `[0,P-1]`. Output is `2^n` little-endian signed-i64 residues in mask order. The function returns output bytes, `-1` for malformed input and `-2` for insufficient capacity or a null output pointer when output is nonempty. Validation precedes capacity checks, and no output is written unless the complete frame is valid and capacity is sufficient. `n=0` is a one-element convolution.

The bounded domain keeps the full subset-indexed workload explicit while exercising the fast rank-transform algorithm. The result is exact modulo `P`; no floating-point arithmetic or probabilistic behavior is involved.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fast_subset_convolution.c`](../../../c/f/fast_subset_convolution.c) |
| C3 | [`c3/f/fast_subset_convolution.c3`](../../../c3/f/fast_subset_convolution.c3) |
| C++ | [`cpp/f/fast_subset_convolution.cpp`](../../../cpp/f/fast_subset_convolution.cpp) |
| Elisa | [`elisa/f/fast_subset_convolution.elisa`](../../../elisa/f/fast_subset_convolution.elisa) |
| Nim | [`nim/f/fast_subset_convolution.nim`](../../../nim/f/fast_subset_convolution.nim) |
| Odin | [`odin/f/fast_subset_convolution.odin`](../../../odin/f/fast_subset_convolution.odin) |
| Rust | [`rust/f/fast_subset_convolution.rs`](../../../rust/f/fast_subset_convolution.rs) |
| V | [`v/f/fast_subset_convolution.v`](../../../v/f/fast_subset_convolution.v) |
| Zig | [`zig/f/fast_subset_convolution.zig`](../../../zig/f/fast_subset_convolution.zig) |

The primary oracle is [`fast_subset_convolution_oracle.py`](../../fast_subset_convolution_oracle.py), and the independent verifier model is [`fast_subset_convolution_verifier_oracle.py`](../../fast_subset_convolution_verifier_oracle.py).

## Attribution and rights

The algorithm is attributed to the chapter “Fast Subset Convolution,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_518. The book is copyrighted by Springer Science+Business Media; this package contains no copied chapter text or code. The implementations are independently written from the mathematical operation and standard ranked-transform method. This attribution does not grant rights to redistribute the book.
