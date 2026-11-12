# Division of Polynomials

This package implements the Library Checker operation over the prime field
F_998244353. Given nonzero polynomials f and g, it returns the unique q and r
satisfying f = q*g + r and deg(r) < deg(g). Coefficients are stored in
ascending degree order. The official task requires nonzero leading
coefficients and permits N,M <= 500000; this profile bounds each degree
length to 64 so straightforward long division stays small and deterministic.

The input ABI is [N, M, f_0, ..., f_(N-1), g_0, ..., g_(M-1)]. Valid lengths
are exactly 2 + N + M; every coefficient is in [0, 998244352], and both last
coefficients must be nonzero.

The output is a little-endian byte array of signed 64-bit words:

    [quotient_count, remainder_count, q_0, ..., q_(quotient_count-1),
     r_0, ..., r_(remainder_count-1)]

The two counts give the canonical coefficient lengths, so a zero polynomial
has count zero and no coefficient words. Coefficients use ascending degree
order. The function returns the byte count on success, -1 for malformed
input, and -2 for null or undersized output. Errors write no bytes. The
maximum output is 536 bytes. The implementation uses at most
(N-M+1)*M modular updates when N >= M, giving O(N*M) time and 1024 bytes
of fixed quotient/remainder workspace.

This operation differs from crc_polynomial_division, which divides encoded
bit strings over GF(2), and from inv_of_polynomials, which uses extended
Euclid to compute an inverse modulo a polynomial when the required gcd
condition holds. Here division is over F_998244353 and returns both the
quotient and the ordinary Euclidean remainder; no coprimality condition is
needed because the input divisor is nonzero.

The primary oracle uses descending long division. The independent oracle
reverses both polynomials, computes the needed reciprocal series coefficients,
forms the quotient by convolution, and reconstructs the remainder from
f-q*g.

The official task specifies the identity, degree condition, coefficient
constraints, and zero-polynomial output convention in the
[Library Checker task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/division_of_polynomials/task.md).
Its [official limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/division_of_polynomials/info.toml)
set N_MAX = 500000 and MOD = 998244353. The bound of 64 and byte ABI are
local profile choices.

## Ports

- [C](../../../c/d/division_of_polynomials.c)
- [C3](../../../c3/d/division_of_polynomials.c3)
- [C++](../../../cpp/d/division_of_polynomials.cpp)
- [Elisa](../../../elisa/d/division_of_polynomials.elisa)
- [Mojo](../../../mojo/d/division_of_polynomials.mojo)
- [Nim](../../../nim/d/division_of_polynomials.nim)
- [Odin](../../../odin/d/division_of_polynomials.odin)
- [Rust](../../../rust/d/division_of_polynomials.rs)
- [V](../../../v/d/division_of_polynomials.v)
- [Zig](../../../zig/d/division_of_polynomials.zig)

The implementations and fixtures are clean-room work based on the cited
mathematical contract. See [RIGHTS.md](RIGHTS.md).

Package files: [workload and fixtures](workload.json), [primary oracle](primary_oracle.py),
[independent oracle](independent_oracle.py), and [static package checker](verify_workload.py).
The workload is registered with the shared byte-output runner and verifier. No
programs, tests, or checkers were run during suite integration.
