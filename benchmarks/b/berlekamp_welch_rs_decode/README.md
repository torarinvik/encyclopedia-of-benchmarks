# Berlekamp–Welch Reed–Solomon decoding

Recover a low-degree polynomial from a bounded set of noisy evaluations. The
primary algorithm builds the Berlekamp–Welch homogeneous system for a numerator
polynomial and an error-locator polynomial, solves it over a finite field,
divides the polynomials, and verifies the mismatch bound. This is a distinct
decoding method from [`misc_reed_solomon`](../../m/misc_reed_solomon/README.md),
which specializes a shortened GF(2^8) encoder and syndrome decoder to at most
one changed symbol, and from [`berlekamp_massey`](../berlekamp_massey/README.md),
which infers a linear recurrence from a sequence.

## Contract

Input is `[n,k,t,y_0,...,y_(n-1)]`. Evaluation points are the distinct field
elements `x_i=i` in the prime field GF(7). The bounds are `2<=n<=7`,
`1<=k<=min(3,n)`, `0<=t<=2`, and `2t<=n-k`; each received symbol is in
`0..6`. The decoded polynomial has degree less than `k`, and a successful
decode is accepted only when at most `t` received values disagree with its
evaluations. A valid input with no such polynomial returns `0`; malformed
input returns `-1`.

The result packs the fixed `k` coefficients in increasing degree order as
`1 + c_0 + 7*c_1 + 7^2*c_2`. Leading zero coefficients are retained in the
fixed-width encoding, so valid outputs are `1..343`. The maximum valid input
has 10 i64 values; an extra trailing value is parseable but invalid. The
workload bounds scratch storage to 1,024 bytes.

For the primary decoder, write `Q(x_i)=y_i E(x_i)` with
`deg(E)<=t` and `deg(Q)<k+t`. Solving this homogeneous system over GF(7) takes
`O(n(k+2t)^2)` field operations with bounded Gaussian elimination; polynomial
division and the final mismatch check are also bounded by these dimensions.
The independent oracle enumerates all `7^k` candidate coefficient vectors
and directly counts disagreements.

The method follows Welch and Berlekamp's [patent on error correction for
algebraic block codes](https://patents.google.com/patent/US4633470A/en); the
evaluation-form equations and unique-decoding conditions are also summarized
in Appendix A.1 of Trevisan's [coding-theory survey hosted by Stanford](https://theory.stanford.edu/~trevisan/pubs/codingsurvey.pdf).
Only algorithm ideas were consulted; all contracts, fixtures, references, and
ports are clean-room work.

| Language | Port |
|---|---|
| C | [c/b/berlekamp_welch_rs_decode.c](../../../c/b/berlekamp_welch_rs_decode.c) |
| C3 | [c3/b/berlekamp_welch_rs_decode.c3](../../../c3/b/berlekamp_welch_rs_decode.c3) |
| C++ | [cpp/b/berlekamp_welch_rs_decode.cpp](../../../cpp/b/berlekamp_welch_rs_decode.cpp) |
| Elisa | [elisa/b/berlekamp_welch_rs_decode.elisa](../../../elisa/b/berlekamp_welch_rs_decode.elisa) |
| Mojo | [mojo/b/berlekamp_welch_rs_decode.mojo](../../../mojo/b/berlekamp_welch_rs_decode.mojo) |
| Nim | [nim/b/berlekamp_welch_rs_decode.nim](../../../nim/b/berlekamp_welch_rs_decode.nim) |
| Odin | [odin/b/berlekamp_welch_rs_decode.odin](../../../odin/b/berlekamp_welch_rs_decode.odin) |
| Rust | [rust/b/berlekamp_welch_rs_decode.rs](../../../rust/b/berlekamp_welch_rs_decode.rs) |
| V | [v/b/berlekamp_welch_rs_decode.v](../../../v/b/berlekamp_welch_rs_decode.v) |
| Zig | [zig/b/berlekamp_welch_rs_decode.zig](../../../zig/b/berlekamp_welch_rs_decode.zig) |
