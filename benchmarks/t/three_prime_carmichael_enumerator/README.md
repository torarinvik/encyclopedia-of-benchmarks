# Three-prime Carmichael-number enumeration

Enumerate Carmichael numbers `p1*p2*p3` with distinct prime factors
`p1 < p2 < p3` and `p1 <= limit`. Input is `[limit]`, where
`2 <= limit <= 61`. The task's historical “strong pseudoprimes” title is
misleading: the operation enumerates Carmichael triples and does not perform a
Miller–Rabin test.

The primary follows the number-theoretic parameterization for each prime
`p1`, derives candidate factors from bounded parameters `h3` and `d`, and
filters the resulting factors for primality and the Carmichael congruence. It
emits a little-endian u32 record stream: a u32 triple count followed by each
`(p1,p2,p3)` in enumeration order. The source bound yields 69 triples at
`limit=61`, so the maximum output is 832 bytes. The independent reference
checks the Carmichael property by Korselt's criterion rather than relying on
the source's final congruence filter. Time is bounded by the small nested
parameter loops and primality checks; scratch space is `O(1)`.

This is distinct from [`carmichael_number`](../carmichael_number/README.md),
which classifies a supplied integer, and from [`miller_rabin`](../../m/miller_rabin/README.md),
which tests a supplied integer against bases. The [Rosetta Code task](https://rosettagit.org/tasks/carmichael-3-strong-pseudoprimes/)
and its linked mathematical notes are used as algorithm references only. No
task code, prose, examples, or tests are copied.

| Language | Port |
|---|---|
| C | [c/t/three_prime_carmichael_enumerator.c](../../../c/t/three_prime_carmichael_enumerator.c) |
| C3 | [c3/t/three_prime_carmichael_enumerator.c3](../../../c3/t/three_prime_carmichael_enumerator.c3) |
| C++ | [cpp/t/three_prime_carmichael_enumerator.cpp](../../../cpp/t/three_prime_carmichael_enumerator.cpp) |
| Elisa | [elisa/t/three_prime_carmichael_enumerator.elisa](../../../elisa/t/three_prime_carmichael_enumerator.elisa) |
| Mojo | [mojo/t/three_prime_carmichael_enumerator.mojo](../../../mojo/t/three_prime_carmichael_enumerator.mojo) |
| Nim | [nim/t/three_prime_carmichael_enumerator.nim](../../../nim/t/three_prime_carmichael_enumerator.nim) |
| Odin | [odin/t/three_prime_carmichael_enumerator.odin](../../../odin/t/three_prime_carmichael_enumerator.odin) |
| Rust | [rust/t/three_prime_carmichael_enumerator.rs](../../../rust/t/three_prime_carmichael_enumerator.rs) |
| V | [v/t/three_prime_carmichael_enumerator.v](../../../v/t/three_prime_carmichael_enumerator.v) |
| Zig | [zig/t/three_prime_carmichael_enumerator.zig](../../../zig/t/three_prime_carmichael_enumerator.zig) |
