# Pollard p−1 factorization

This package benchmarks Pollard's p−1 stage-1 method: modular exponentiation makes `A^M−1` divisible by a factor whose `p−1` divides the accumulated smooth exponent, and a gcd extracts that factor. It is distinct from the local Pollard-rho profiles, which use polynomial walks and cycle detection.

## Contract

The `i64_array_scalar` input is `[N,B,A]`, with `2<=N<=1,000,000,000`, smoothness bound `2<=B<=64`, and base `1<=A<N`. A shared factor `gcd(A,N)>1` is returned immediately. Otherwise, for every prime `q<=B` in increasing order, compute the greatest power `e=q^k<=B`, replace the state by `state^e mod N`, and compute `g=gcd(|state−1|,N)`. Continue when `g=1`, return a proper divisor when `1<g<N`, and return zero if `g=N` or all stages finish without a factor. Malformed input, including trailing values, returns `-1`. Valid input length is 3; one trailing word is parseable for rejection.

All modular products fit signed 64-bit arithmetic under the `N<=10^9` bound. The declared fixed workspace is 1,024 bytes.

The primary oracle mirrors successive maximal-prime-power modular exponentiation. The independent oracle generates primes by trial division, accumulates the exponent as a Python big integer, and recomputes each stage directly with modular exponentiation.

## Provenance

The clean-room implementation follows the Pollard p−1 description in [CP-Algorithms — Integer factorization](https://cp-algorithms.com/algebra/factorization.html#pollards-p-1-method). CP-Algorithms is licensed CC BY-SA 4.0; this project uses the algorithm description only. No code, article prose, examples, or tasks were copied. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), both oracles, and the static package checker.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/pollard_p_minus_one_factorization.c`](../../../c/p/pollard_p_minus_one_factorization.c) |
| C3 | [`c3/p/pollard_p_minus_one_factorization.c3`](../../../c3/p/pollard_p_minus_one_factorization.c3) |
| C++ | [`cpp/p/pollard_p_minus_one_factorization.cpp`](../../../cpp/p/pollard_p_minus_one_factorization.cpp) |
| Elisa | [`elisa/p/pollard_p_minus_one_factorization.elisa`](../../../elisa/p/pollard_p_minus_one_factorization.elisa) |
| Mojo | [`mojo/p/pollard_p_minus_one_factorization.mojo`](../../../mojo/p/pollard_p_minus_one_factorization.mojo) |
| Nim | [`nim/p/pollard_p_minus_one_factorization.nim`](../../../nim/p/pollard_p_minus_one_factorization.nim) |
| Odin | [`odin/p/pollard_p_minus_one_factorization.odin`](../../../odin/p/pollard_p_minus_one_factorization.odin) |
| Rust | [`rust/p/pollard_p_minus_one_factorization.rs`](../../../rust/p/pollard_p_minus_one_factorization.rs) |
| V | [`v/p/pollard_p_minus_one_factorization.v`](../../../v/p/pollard_p_minus_one_factorization.v) |
| Zig | [`zig/p/pollard_p_minus_one_factorization.zig`](../../../zig/p/pollard_p_minus_one_factorization.zig) |

The shared `i64_array_scalar` runner and verifier register this package.
