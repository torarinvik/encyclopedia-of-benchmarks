# Elias–Fano monotone sequence encoding

Elias–Fano stores a bounded nondecreasing integer sequence by splitting every
value into low bits and a unary-positioned high part. The benchmark builds that
representation, accesses every value from it, and returns a weighted checksum.
It is distinct from the repository's rank/select bitvector encodings: this
package compresses an integer sequence drawn from a bounded universe.

## Contract

- `i64_array_scalar` input is `[n,U,x_0,...,x_(n-1)]`.
- `1<=n<=32`, `0<=U<=1000000`, `n<=U+1`, and the sequence is nondecreasing
  with every value in `[0,U]`. The frame contains exactly `n+2` words.
- Return `sum((i+1)*x_i)` after encoding and accessing every value, or `-1` for
  invalid input. The maximum result is `528000000`.

## Deterministic profile

Treat the universe as `0..U`, inclusive. Choose the low width `ell` as the
largest integer satisfying `n*2^ell<=U+1`, equivalent to
`floor(log2((U+1)/n))`. Store `x_i mod 2^ell` in the low array. In a high bit
vector of length `floor(U/2^ell)+n`, set bit `(x_i div 2^ell)+i` for each
sequence position `i`. Decode by scanning high bits for one positions `p_i`,
recovering `(p_i-i)*2^ell+low_i`, and accumulating the checksum.

The profile takes `O(n+U/2^ell)` time and `O(n*ell+U/2^ell)` bits of storage.
The independent oracle validates the same interface and computes the checksum
directly from the input values without constructing the encoding.

## Source

- Peter Elias, [Efficient Storage and Retrieval by Content and Address of
  Static Files](https://doi.org/10.1145/321812.321820), *Journal of the ACM*
  21(2), 246–260 (1974).
- G. E. Pibiri and R. Venturini, [Inverted Index Compression](https://pages.di.unipi.it/pibiri/papers/ii_compression.pdf),
  for a clear high/low representation and `select`-based access description.
