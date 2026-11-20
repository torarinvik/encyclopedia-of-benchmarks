# Strong, weak, and balanced prime distribution

This benchmark counts primes by comparing each prime with the arithmetic mean
of its immediate prime neighbors. The RosettaGit [public task-title
index](https://rosettagit.org/tasks/) supplied the discovery title only;
definitions come from the independent OEIS entries for [strong
primes](https://oeis.org/A051634), [weak primes](https://oeis.org/A051635),
and [balanced primes](https://oeis.org/A006562).

## Contract

- ABI: `i64_array_scalar`; exported symbol:
  `strong_weak_balanced_prime_distribution`.
- Input is exactly `[inclusive_limit]`, with length supplied separately.
- `3 <= inclusive_limit <= 100000`. Prime `2` is excluded because it has no
  preceding prime; all primes from `3` through the inclusive limit are
  classified once.
- For a prime `p`, let `previous` and `following` be its immediately adjacent
  primes in the full prime sequence. It is strong when
  `2*p > previous+following`, weak when `2*p < previous+following`, and
  balanced when they are equal. Comparisons use exact integer arithmetic.
- Return `strong_count * 10000000000 + weak_count * 100000 + balanced_count`.
  Each count is below 100000, so the fixed-width base-100000 fields do not
  overlap and the result fits signed 64-bit arithmetic.
- Return `-1` for malformed or out-of-range frames. Maximum valid input length
  is 1; maximum parseable length is 2 (one possible trailing word). A non-null
  input pointer is required, including for a zero-length frame.

The primary port sieves all integers through `2*inclusive_limit`, then classifies
the middle value of each consecutive prime triple as the next prime arrives.
The ceiling is sufficient: Bertrand's postulate guarantees a prime strictly
between `p` and `2p` for every prime `p > 1`, so the successor of every counted
prime is below `2*inclusive_limit`. The sieve follows the mathematical
description in CP-Algorithms' [Sieve of Eratosthenes](https://cp-algorithms.com/algebra/sieve-of-eratosthenes.html).

The independent reference builds the prime list by incremental trial division
against already discovered primes, then classifies adjacent triples. This uses
a different primality-generation method from the primary sieve. OEIS sequences
A051634, A051635, and A006562 also provide an independent check of the first
terms and the pinned distribution fixtures. In particular, the limit-1000
fixture's balanced count of 15 agrees with OEIS [A055206](https://oeis.org/A055206),
which counts balanced primes below powers of ten. The maximum-limit fixture
uses the count of strong primes below `10^5` in OEIS
[A159687](https://oeis.org/A159687), the balanced count from A055206, and the
total prime count in [A006880](https://oeis.org/A006880): among the 9591 primes
from 3 through 100000, 4543 are strong, 434 are balanced, and the remaining
4614 are weak.

This is the number-theoretic use of “strong prime.” It is distinct from a
strong probable-prime test such as Miller–Rabin and from cryptographic
strong-prime criteria based on factors of `p-1` and `p+1`.

The package references are [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and
[`verify_workload.py`](verify_workload.py). The static package inventory is
[`check_inventory.py`](check_inventory.py), exposing `static_issues()` and
`verify()`.

## Complexity

For limit `L`, the primary takes `O(L log log L)` time and `O(L)` space. The
independent reference takes `O(L sqrt(L))` worst-case trial-division work and
`O(L)` space for its prime list.

## Language ports

| Language | Source |
|---|---|
| C | [strong_weak_balanced_prime_distribution.c](../../../c/s/strong_weak_balanced_prime_distribution.c) |
| C3 | [strong_weak_balanced_prime_distribution.c3](../../../c3/s/strong_weak_balanced_prime_distribution.c3) |
| C++ | [strong_weak_balanced_prime_distribution.cpp](../../../cpp/s/strong_weak_balanced_prime_distribution.cpp) |
| Elisa | [strong_weak_balanced_prime_distribution.elisa](../../../elisa/s/strong_weak_balanced_prime_distribution.elisa) |
| Mojo | [strong_weak_balanced_prime_distribution.mojo](../../../mojo/s/strong_weak_balanced_prime_distribution.mojo) |
| Nim | [strong_weak_balanced_prime_distribution.nim](../../../nim/s/strong_weak_balanced_prime_distribution.nim) |
| Odin | [strong_weak_balanced_prime_distribution.odin](../../../odin/s/strong_weak_balanced_prime_distribution.odin) |
| Rust | [strong_weak_balanced_prime_distribution.rs](../../../rust/s/strong_weak_balanced_prime_distribution.rs) |
| V | [strong_weak_balanced_prime_distribution.v](../../../v/s/strong_weak_balanced_prime_distribution.v) |
| Zig | [strong_weak_balanced_prime_distribution.zig](../../../zig/s/strong_weak_balanced_prime_distribution.zig) |
