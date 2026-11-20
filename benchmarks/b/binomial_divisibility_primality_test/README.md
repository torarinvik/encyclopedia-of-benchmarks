# Binomial-divisibility primality test

Given one integer `n` in `2..1000`, return `1` exactly when every interior
binomial coefficient in row `n` of Pascal's triangle is divisible by `n`; in
all other valid cases return `0`. The input is exactly `[n]`. Values outside
the contract or malformed frames return `-1`.

The implementation constructs row `n` modulo `n` with descending in-place
Pascal updates, so each cell uses addition and reduction only; division modulo
a composite is never attempted. It performs `O(n^2)` modular additions and
uses `O(n)` signed 64-bit cells. The primary oracle uses this recurrence; the
independent reference uses trial division to determine the truth value.

Rosetta Code labels its task "AKS test for primes", but its discussion
explicitly distinguishes the binomial-divisibility criterion from the
polynomial-time AKS algorithm. This benchmark uses the accurate criterion name
and does not claim to implement AKS. The task and RosettaGit discussion are
algorithm-discovery references only. Their code, task text, examples, and
community tests were not reused; ports and fixtures are clean-room.

| Language | Port |
|---|---|
| C | [c/b/binomial_divisibility_primality_test.c](../../../c/b/binomial_divisibility_primality_test.c) |
| C3 | [c3/b/binomial_divisibility_primality_test.c3](../../../c3/b/binomial_divisibility_primality_test.c3) |
| C++ | [cpp/b/binomial_divisibility_primality_test.cpp](../../../cpp/b/binomial_divisibility_primality_test.cpp) |
| Elisa | [elisa/b/binomial_divisibility_primality_test.elisa](../../../elisa/b/binomial_divisibility_primality_test.elisa) |
| Mojo | [mojo/b/binomial_divisibility_primality_test.mojo](../../../mojo/b/binomial_divisibility_primality_test.mojo) |
| Nim | [nim/b/binomial_divisibility_primality_test.nim](../../../nim/b/binomial_divisibility_primality_test.nim) |
| Odin | [odin/b/binomial_divisibility_primality_test.odin](../../../odin/b/binomial_divisibility_primality_test.odin) |
| Rust | [rust/b/binomial_divisibility_primality_test.rs](../../../rust/b/binomial_divisibility_primality_test.rs) |
| V | [v/b/binomial_divisibility_primality_test.v](../../../v/b/binomial_divisibility_primality_test.v) |
| Zig | [zig/b/binomial_divisibility_primality_test.zig](../../../zig/b/binomial_divisibility_primality_test.zig) |
