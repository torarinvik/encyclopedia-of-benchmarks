# Prime-modulus p-free factorial

Compute `n!` modulo a prime `p` after removing every factor of `p` from the
factorization of `n!`. Input is `[n, p]`, with `0 <= n <= INT64_MAX` and prime
`2 <= p <= 1009`; return the resulting residue in `0..p-1`, or `-1` for an
invalid frame or nonprime modulus.

The primary method precomputes factorial residues below `p`, then applies the
Wilson-block recurrence while repeatedly dividing `n` by `p`. It takes
`O(p + log_p(n+1))` time and `O(p)` scratch storage. The independent reference
forms each full residue block explicitly and exponentiates its product, rather
than using Wilson's theorem to replace that block product by `-1`.

This is a standalone unit-factorial operation with a large-`n`, small-prime
profile. [`binomial_coefficient_prime_power`](../binomial_coefficient_prime_power/README.md)
also uses p-free factorial parts internally, but returns a binomial coefficient
modulo a prime power and combines those parts with p-adic valuations and
denominator handling. That shared subroutine does not duplicate this direct
output benchmark.

The [CP-Algorithms factorial-modulo-p article](https://cp-algorithms.com/algebra/factorial-modulo.html)
is the mathematical reference; its stated CC BY-SA 4.0 terms apply to that
page. This package uses the algorithm idea only. Contracts, implementations,
references, and fixtures are independently authored.

| Language | Port |
|---|---|
| C | [c/p/prime_modulus_p_free_factorial.c](../../../c/p/prime_modulus_p_free_factorial.c) |
| C3 | [c3/p/prime_modulus_p_free_factorial.c3](../../../c3/p/prime_modulus_p_free_factorial.c3) |
| C++ | [cpp/p/prime_modulus_p_free_factorial.cpp](../../../cpp/p/prime_modulus_p_free_factorial.cpp) |
| Elisa | [elisa/p/prime_modulus_p_free_factorial.elisa](../../../elisa/p/prime_modulus_p_free_factorial.elisa) |
| Mojo | [mojo/p/prime_modulus_p_free_factorial.mojo](../../../mojo/p/prime_modulus_p_free_factorial.mojo) |
| Nim | [nim/p/prime_modulus_p_free_factorial.nim](../../../nim/p/prime_modulus_p_free_factorial.nim) |
| Odin | [odin/p/prime_modulus_p_free_factorial.odin](../../../odin/p/prime_modulus_p_free_factorial.odin) |
| Rust | [rust/p/prime_modulus_p_free_factorial.rs](../../../rust/p/prime_modulus_p_free_factorial.rs) |
| V | [v/p/prime_modulus_p_free_factorial.v](../../../v/p/prime_modulus_p_free_factorial.v) |
| Zig | [zig/p/prime_modulus_p_free_factorial.zig](../../../zig/p/prime_modulus_p_free_factorial.zig) |
