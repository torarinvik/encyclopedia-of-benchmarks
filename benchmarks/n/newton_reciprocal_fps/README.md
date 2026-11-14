# Newton reciprocal of a formal power series

This in-progress profile computes `g = 1/f mod x^N` over F_998244353 using Newton precision doubling. The existing [`inv_of_formal_power_series`](../../i/inv_of_formal_power_series/README.md) ports use a coefficient recurrence; their Newton oracle does not time this method.

Input is `[N, f_0, ..., f_(N-1)]`, `1 <= N <= 64`, each coefficient in `0..998244352`, with `f_0 != 0`. The byte-output ABI returns N little-endian i64 residues and result `8*N`; malformed or null input returns -1, and valid input with a null or short output returns -2 without writes. Maximum valid and parseable input lengths are 65 and 66 words, and maximum output is 512 bytes.

The iteration starts with the inverse of the constant coefficient and repeatedly computes `g <- g*(2-f*g)` modulo `x^min(2m,N)`, doubling the known precision `m`. With the bounded schoolbook multiplications here, time is O(N²) field operations and space is O(N); no fast-convolution performance claim is made.

[FLINT's inversion documentation](https://flintlib.org/doc/nmod_poly/inv_series.html) describes both the recurrence and Newton methods. [Library Checker](https://github.com/yosupo06/library-checker-problems) provides the operation index and uses Apache-2.0. Only mathematical ideas are used; code and fixtures are independently written. Drafts in all ten languages, a workload, a static inventory checker, and byte-output suite registration are present. The Newton primary and coefficient-recurrence reference reuse the existing local reciprocal package's oracles. Nothing has been run; further review remains necessary.

The verifier source includes maximum-length geometric-series and highest-degree
correction checks. These checks have not been executed.
