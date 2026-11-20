# Lucas binomial coefficient modulo a small prime

Given `[n, k, p]`, return `C(n,k) mod p` for `0 <= k <= n <= INT64_MAX` and
prime `2 <= p <= 1009`. Invalid input returns `-1`.

The implementation precomputes factorials and inverse factorials below `p`,
then applies Lucas' theorem to the base-`p` digits of `n` and `k`. A digit with
`k_i > n_i` makes the result zero. The running time is `O(p + log_p(n+1))`
and auxiliary space is `O(p)`.

This computes binomial coefficients for arbitrarily large signed-64-bit `n`
when the modulus is prime. It is distinct from the bounded exact `combinations`
benchmark, the prime-power residue profile, and the standalone p-free
factorial profile.

The algorithm idea is described in [CP-Algorithms' binomial coefficient
reference](https://cp-algorithms.com/combinatorics/binomial-coefficients.html)
and [OI Wiki's Lucas theorem
reference](https://en.oi-wiki.org/math/lucas/). The package is a clean-room
implementation; see [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/b/binomial_coefficient_lucas.c](../../../c/b/binomial_coefficient_lucas.c) |
| C3 | [c3/b/binomial_coefficient_lucas.c3](../../../c3/b/binomial_coefficient_lucas.c3) |
| C++ | [cpp/b/binomial_coefficient_lucas.cpp](../../../cpp/b/binomial_coefficient_lucas.cpp) |
| Elisa | [elisa/b/binomial_coefficient_lucas.elisa](../../../elisa/b/binomial_coefficient_lucas.elisa) |
| Mojo | [mojo/b/binomial_coefficient_lucas.mojo](../../../mojo/b/binomial_coefficient_lucas.mojo) |
| Nim | [nim/b/binomial_coefficient_lucas.nim](../../../nim/b/binomial_coefficient_lucas.nim) |
| Odin | [odin/b/binomial_coefficient_lucas.odin](../../../odin/b/binomial_coefficient_lucas.odin) |
| Rust | [rust/b/binomial_coefficient_lucas.rs](../../../rust/b/binomial_coefficient_lucas.rs) |
| V | [v/b/binomial_coefficient_lucas.v](../../../v/b/binomial_coefficient_lucas.v) |
| Zig | [zig/b/binomial_coefficient_lucas.zig](../../../zig/b/binomial_coefficient_lucas.zig) |
