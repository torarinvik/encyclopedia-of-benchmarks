# Ψ-based suffix-array access

This package implements the `A[i]` access core of the Grossi–Vitter
Ψ-based compressed suffix array described in Chapter 82. Starting at one
suffix-array rank, it follows Ψ until it reaches a sampled suffix-array value,
then reverses the number of text-position advances with wraparound. It does
not implement the chapter's hierarchical bit encoding or claim its compressed
space bounds.

## Contract

ABI: `i64_array_bytes_output`; symbol: `psi_suffix_array_access`. Input is
`[n,query_rank,stride,psi_0,...,psi_(n-1),sample_A_0,...,sample_A_(n-1)]`.
The bound is `1 <= n <= 32`, `0 <= query_rank < n`, and `1 <= stride <= n`.
Ranks in the input are zero-based; suffix-array values `A[i]` are one-based.
`psi[i]` is the zero-based rank `j` satisfying `A[j] = A[i]+1`, with `n`
wrapping to `1`. Ψ must be a permutation consisting of one n-cycle.

The final n entries contain the sampled SA value at each rank, or zero when
unsampled. The chapter leaves sample placement and compressed encoding
unspecified. This profile chooses the deterministic text-position phase that
samples zero-based text offsets divisible by `stride`; because stored SA
values are one-based, `sample_A[i]` equals `A[i]` exactly when
`(A[i] - 1) mod stride == 0`, and is zero otherwise. This phase gives a sample
within at most `stride - 1` forward Ψ steps even across the cycle boundary.
The ports validate the full cycle and sample predicate.

Starting at `query_rank`, the access walk repeatedly applies `rank = psi[rank]`
until it reaches a nonzero sample. After `hops` steps, the result is
`A[query_rank] = ((sample_A[rank] - 1 - hops) mod n) + 1`. Since Ψ advances
text position by one and samples occur every `stride` positions on the cyclic
text domain, `0 <= hops < stride`. Output is two little-endian
unsigned 64-bit words `[A[query_rank],hops]` (16 bytes). Invalid framing,
permutation/cycle, or sample data returns `-1`; null or short output storage
returns `-2` without writes. Maximum input length is 67 words and fixed
workspace is 1,024 bytes.

## Source and rights

Source: Djamel Belazzougui, Veli Mäkinen, and Daniel Valenzuela, “Compressed
Suffix Array,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_82`](https://doi.org/10.1007/978-1-4939-2864-4_82),
section “Ψ-Based CSAs.” The chapter defines the Ψ successor relation and
sampled-SA access but leaves the hierarchical bit encoding to the cited
Grossi–Vitter paper. This package covers only the explicit-array access core.
See [`RIGHTS.md`](RIGHTS.md) for rights status.

Primary oracle: [`psi_suffix_array_access_oracle.py`](../../psi_suffix_array_access_oracle.py).
Independent verifier: [`psi_suffix_array_access_verifier_oracle.py`](../../psi_suffix_array_access_verifier_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`c/p/psi_suffix_array_access.c`](../../../c/p/psi_suffix_array_access.c) |
| C3 | [`c3/p/psi_suffix_array_access.c3`](../../../c3/p/psi_suffix_array_access.c3) |
| C++ | [`cpp/p/psi_suffix_array_access.cpp`](../../../cpp/p/psi_suffix_array_access.cpp) |
| Elisa | [`elisa/p/psi_suffix_array_access.elisa`](../../../elisa/p/psi_suffix_array_access.elisa) |
| Nim | [`nim/p/psi_suffix_array_access.nim`](../../../nim/p/psi_suffix_array_access.nim) |
| Odin | [`odin/p/psi_suffix_array_access.odin`](../../../odin/p/psi_suffix_array_access.odin) |
| Rust | [`rust/p/psi_suffix_array_access.rs`](../../../rust/p/psi_suffix_array_access.rs) |
| V | [`v/p/psi_suffix_array_access.v`](../../../v/p/psi_suffix_array_access.v) |
| Zig | [`zig/p/psi_suffix_array_access.zig`](../../../zig/p/psi_suffix_array_access.zig) |
