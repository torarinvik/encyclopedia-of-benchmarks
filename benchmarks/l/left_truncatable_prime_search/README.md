# Left-truncatable prime search

This benchmark finds the largest left-truncatable prime for a bounded base and
digit count. RosettaGit's [task-title index](https://rosettagit.org/tasks/)
identified the topic; algorithm specifics come from Angell and Godwin's
[1977 paper](https://doi.org/10.1090/S0025-5718-1977-0427213-2) and the
independent [OEIS A103443 entry](https://oeis.org/A103443/internal).

## Contract

- ABI: `i64_array_scalar`; exported symbol: `left_truncatable_prime_search`.
- Input is exactly `[base, max_digits]`, with length supplied separately.
- `3 <= base <= 16`, `1 <= max_digits <= 10`, and `base^max_digits <= 100000`.
  The latter gives a common bounded search interval and ensures all values fit
  comfortably in signed 64-bit arithmetic.
- A value is left-truncatable when its base-`base` representation contains no
  zero digit and it remains prime after successively deleting leading digits,
  including the final one-digit suffix.
- Return the numerically largest qualifying prime with at most
  `max_digits` digits. Return `-1` for malformed/out-of-range frames. The
  bounded base range always includes a one-digit prime, so the valid result is
  positive.
- Maximum valid input length is 2; maximum parseable length is 3. A non-null
  input pointer is required even for a zero-length frame.

The primary search starts with one-digit primes below the base. For each
frontier value `p` with `s` digits, it considers
`d * base^s + p` for `1 <= d < base`, retains prime candidates, and advances
to the next digit length. This breadth-first construction ensures that every
retained candidate already has a prime suffix chain. The independent oracle
uses a sieve up to `base^max_digits`, scans every integer below that bound,
and tests its successive suffixes directly.

This profile is distinct from local [`problem37`](../../p/problem37/README.md),
which sums the fixed decimal primes that remain prime under both left and
right truncation. Here the base is an input, only left truncation is tested,
and the result is the maximum found value.

The primary is [`primary_oracle.py`](primary_oracle.py); the independent
reference is [`independent_oracle.py`](independent_oracle.py). The fixtures
include published largest values for bases 3, 4, and 5, small decimal cases,
domain limits, and malformed/null frames. The package-local static inventory
is [`check_inventory.py`](check_inventory.py), exposing `static_issues()` and
`verify()`.

## Complexity

For a base-b search through D digits, breadth-first enumeration visits at most
`sum((b-1)^j, j=1..D)` digit strings and applies trial division up to the
candidate square root. The contract additionally requires `b^D <= 100000`.
The independent verifier uses an `O(b^D log log(b^D))` sieve and an
`O(D b^D)` direct suffix scan.

## Language ports

| Language | Source |
|---|---|
| C | [left_truncatable_prime_search.c](../../../c/l/left_truncatable_prime_search.c) |
| C3 | [left_truncatable_prime_search.c3](../../../c3/l/left_truncatable_prime_search.c3) |
| C++ | [left_truncatable_prime_search.cpp](../../../cpp/l/left_truncatable_prime_search.cpp) |
| Elisa | [left_truncatable_prime_search.elisa](../../../elisa/l/left_truncatable_prime_search.elisa) |
| Mojo | [left_truncatable_prime_search.mojo](../../../mojo/l/left_truncatable_prime_search.mojo) |
| Nim | [left_truncatable_prime_search.nim](../../../nim/l/left_truncatable_prime_search.nim) |
| Odin | [left_truncatable_prime_search.odin](../../../odin/l/left_truncatable_prime_search.odin) |
| Rust | [left_truncatable_prime_search.rs](../../../rust/l/left_truncatable_prime_search.rs) |
| V | [left_truncatable_prime_search.v](../../../v/l/left_truncatable_prime_search.v) |
| Zig | [left_truncatable_prime_search.zig](../../../zig/l/left_truncatable_prime_search.zig) |
