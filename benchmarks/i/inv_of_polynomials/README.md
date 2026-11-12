# Inverse of polynomials modulo a polynomial

This package implements Library Checker `inv_of_polynomials`, a polynomial
inverse in the quotient ring `F_998244353[x]/(g)`. Given f and nonzero g, it
returns the unique h with degree(h)<degree(g) and f*h congruent to 1 modulo g,
or reports that no inverse exists. A solution exists exactly when gcd(f,g)=1.
For nonzero constant g, the quotient has only the zero representative, so the
valid output is the empty polynomial h=0.

## Bounded contract

The `i64_array_bytes_output` ABI accepts
`[N,M,a0,...,a(N-1),b0,...,b(M-1)]`. The profile restricts 1<=N,M<=6, each
coefficient to 0..998244352, and both leading coefficients to nonzero. Ports
use polynomial extended Euclid, beginning with `f mod g` and tracking its
Bezout coefficient. A constant gcd is normalized to one; the resulting
coefficient is the canonical representative of degree below `deg(g)` and is
returned as little-endian signed 64-bit coefficients. `T=0`
means the empty polynomial and returns zero bytes. Invalid input or a
non-coprime pair returns -1. A null output or capacity below `8*T` returns
-2 without writing. The maximum input is 14 words and the maximum output is
40 bytes.

This direct profile does not claim the official N,M<=50000 scale. Small
lengths keep polynomial division and Bezout products bounded and visible.

## Distinctness

The local `inv_of_formal_power_series` computes a reciprocal modulo x^N and
exists exactly when the constant coefficient is nonzero. This task uses an
arbitrary modulus polynomial g, can have no inverse when f and g share a
factor, and returns a representative whose degree is below degree(g). Local
polynomial evaluation, regression, convolution, and CRC polynomial division
do not implement this quotient-ring inverse.

The primary oracle uses extended Euclid. The independent verifier constructs
the multiplication-by-f linear map in the quotient basis and solves the
resulting modular linear system by Gaussian elimination. Both return the
same byte-array contract.

## Source and rights

Official statement: [Library Checker — Inv of Polynomials](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/inv_of_polynomials/task.md).
Official bounds: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/inv_of_polynomials/info.toml).
The repository is Apache-2.0. This package uses the operation contract and
modulus as factual specifications; source, workload, oracles, and prose are
clean-room. See [RIGHTS.md](RIGHTS.md).

The workload and static package checker are
[`workload.json`](workload.json) and [`verify_workload.py`](verify_workload.py).
Shared byte-output runner/verifier dispatch and bounds are registered; the
package checker will confirm all ten language ports once they are present.

| Language | Source |
|---|---|
| C | [c/i/inv_of_polynomials.c](../../../c/i/inv_of_polynomials.c) |
| C3 | [c3/i/inv_of_polynomials.c3](../../../c3/i/inv_of_polynomials.c3) |
| C++ | [cpp/i/inv_of_polynomials.cpp](../../../cpp/i/inv_of_polynomials.cpp) |
| Elisa | [elisa/i/inv_of_polynomials.elisa](../../../elisa/i/inv_of_polynomials.elisa) |
| Mojo | [mojo/i/inv_of_polynomials.mojo](../../../mojo/i/inv_of_polynomials.mojo) |
| Nim | [nim/i/inv_of_polynomials.nim](../../../nim/i/inv_of_polynomials.nim) |
| Odin | [odin/i/inv_of_polynomials.odin](../../../odin/i/inv_of_polynomials.odin) |
| Rust | [rust/i/inv_of_polynomials.rs](../../../rust/i/inv_of_polynomials.rs) |
| V | [v/i/inv_of_polynomials.v](../../../v/i/inv_of_polynomials.v) |
| Zig | [zig/i/inv_of_polynomials.zig](../../../zig/i/inv_of_polynomials.zig) |
