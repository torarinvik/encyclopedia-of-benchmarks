# q-binomial coefficient modulo a prime

## Contract

Input is the signed 64-bit vector [T, m, q, n0, k0, ...]. The profile accepts
1 <= T <= 16, prime 2 <= m <= 31, 0 <= q < m, and 0 <= n,k <= 16 with
n,k < m. The modulus and q are shared by all T cases. For each pair, return
the Gaussian binomial coefficient modulo m; it is zero when k > n.

This follows the operation and parameter relationships in the official
Library Checker task, which permits T up to 1,000,000, m up to 1,073,741,824,
and n,k below min(m, 10,000,000). The local bounds intentionally retain a
small bounded profile. The task refers to the standard Gaussian binomial
coefficient definition.

The exported i64-array/byte-output function returns one byte per answer. The
profile guarantees every residue is in 0..30. Invalid input returns -1. A
null output or insufficient output capacity returns -2; errors leave output
untouched.

## Algorithm and distinctness

Ordinary binomial packages do not include the q-weight on subsets. For
0 <= k <= n, the ports fill a bounded table with

G(n,k) = G(n-1,k) + q^(n-k) G(n-1,k-1) (mod m),

using G(n,0)=G(n,n)=1. No modular inverse is needed, so q=0 and q=1 use the
same recurrence as other residues.

The primary oracle uses this recurrence. The independent oracle enumerates
the k-subsets S of {0,...,n-1} and evaluates
sum(q^(sum(S)-k(k-1)/2)) mod m, the subset identity for the Gaussian
binomial. The independent method does not use the table recurrence.

Official task: [Library Checker — q-Binomial Coefficient (Prime Mod)](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/q_binomial_coefficient_prime_mod/task.md).
Official limits: [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/q_binomial_coefficient_prime_mod/info.toml).

## Workload and static review

workload.json covers q=0, q=1, a nontrivial q, q=-1 modulo a prime, k=0,
k=n, k>n, the profile maxima, malformed frames, invalid primes/domains, and
output-capacity/null cases. The two source-specific oracles are
[../../q_binomial_coefficient_prime_mod_oracle.py](../../q_binomial_coefficient_prime_mod_oracle.py)
and
[../../q_binomial_coefficient_prime_mod_independent_oracle.py](../../q_binomial_coefficient_prime_mod_independent_oracle.py).
verify_workload.py statically checks metadata, fixtures, and all ten port
paths without compiling or invoking a port.

## Language ports

| Language | Source |
|---|---|
| C | [c/q/q_binomial_coefficient_prime_mod.c](../../../c/q/q_binomial_coefficient_prime_mod.c) |
| C3 | [c3/q/q_binomial_coefficient_prime_mod.c3](../../../c3/q/q_binomial_coefficient_prime_mod.c3) |
| C++ | [cpp/q/q_binomial_coefficient_prime_mod.cpp](../../../cpp/q/q_binomial_coefficient_prime_mod.cpp) |
| Elisa | [elisa/q/q_binomial_coefficient_prime_mod.elisa](../../../elisa/q/q_binomial_coefficient_prime_mod.elisa) |
| Mojo | [mojo/q/q_binomial_coefficient_prime_mod.mojo](../../../mojo/q/q_binomial_coefficient_prime_mod.mojo) |
| Nim | [nim/q/q_binomial_coefficient_prime_mod.nim](../../../nim/q/q_binomial_coefficient_prime_mod.nim) |
| Odin | [odin/q/q_binomial_coefficient_prime_mod.odin](../../../odin/q/q_binomial_coefficient_prime_mod.odin) |
| Rust | [rust/q/q_binomial_coefficient_prime_mod.rs](../../../rust/q/q_binomial_coefficient_prime_mod.rs) |
| V | [v/q/q_binomial_coefficient_prime_mod.v](../../../v/q/q_binomial_coefficient_prime_mod.v) |
| Zig | [zig/q/q_binomial_coefficient_prime_mod.zig](../../../zig/q/q_binomial_coefficient_prime_mod.zig) |

## Rights

See [RIGHTS.md](RIGHTS.md) for source and rights details.
