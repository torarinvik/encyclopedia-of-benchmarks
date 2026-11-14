# Polynomial discrete antiderivative

Given coefficients of `f(x)` over `F_998244353`, compute coefficients of the
unique polynomial `g` with `g(0)=0` and `g(x+1)-g(x)=f(x)`. This is the
coefficient transform behind a polynomial's prefix sums; existing
[`polynomial_interpolation`](../polynomial_interpolation/README.md) accepts
arbitrary point/value pairs, while Bernoulli and weighted power-sum packages
compute different outputs.

The bounded `i64_array_bytes_output` input is `[n,a0,...,a(n-1)]`, where
`1 <= n <= 32` and every coefficient is a canonical residue modulo
998244353. Output is the `n+1` coefficients of `g` as little-endian i64 words,
including trailing zeros. Invalid or null input returns `-1`; null or short
output returns `-2` without writes. Maximum valid input length is 33 words,
and maximum output is 264 bytes.

The draft solves the triangular coefficient relations of `g(x+1)-g(x)`
from highest degree downward, with modular binomial coefficients and inverses.
It uses O(n²) time and O(n²) space. The independent reference evaluates prefix
sums at consecutive points and converts a Newton forward-difference expansion
to the monomial basis.

The [Library Checker catalog item](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/prefix_sum_of_polynomial/task.md)
provides the operation idea; its repository is Apache-2.0. The bounded contract,
code, and reference are independently authored without copying task text,
implementation, or fixtures.

Status: all ten language drafts, an independent reference, a workload, and
byte-output suite registration are present. Verifier source specifies every
bounded degree, maximum framing, invalid input, and buffer boundaries. Nothing
has been compiled or run.
