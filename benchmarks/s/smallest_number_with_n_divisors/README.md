# Smallest number with `d` divisors

Given a divisor count `d` and an inclusive search cap `limit`, return the
smallest positive integer `N <= limit` with exactly `d` positive divisors.
Return `0` when the valid bounded search has no solution, and `-1` for an
invalid input.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `smallest_number_with_n_divisors`.
- Input is exactly `[d, limit]`, where `1 <= d <= 63` and
  `1 <= limit <= 1,000,000`.
- For valid input, return the least `N` in `1..=limit` for which `tau(N)=d`;
  return `0` if none exists within the supplied cap.
- Malformed, null, or out-of-profile input returns `-1`.
- Maximum valid input length is 2; the maximum parseable length is 3.

If `N = p_1^e_1 ... p_k^e_k`, then `tau(N) = product(e_i + 1)`. To minimize
`N` for a fixed divisor count, it is enough to enumerate nonincreasing
factorizations `d = f_1 ... f_k`, set `e_i = f_i - 1`, and assign those
exponents in order to the first primes `2,3,5,7,11`. The order restriction
avoids duplicate exponent permutations; swapping a larger exponent onto a
smaller prime can only reduce the candidate. Since `d <= 63`, at most five
prime exponents are needed. Candidates above `limit` are pruned during
construction. Each profile checks at most 63 possible factors, and the
nonincreasing search has at most five levels. A number at most 63 has at most
12 positive divisors, so each state has at most 11 children and the depth-first
stack holds fewer than 56 pending states; the ports reserve 128 entries.

This is the inverse problem to [`number_of_positive_divisors`](../../n/number_of_positive_divisors/README.md),
which computes `tau(N)` for a supplied `N`. The separate
[`divisors_count_sequence`](../../d/divisors_count_sequence/README.md) package
uses a linear divisor scan to emit sequence terms; this package searches
exponent profiles directly and supports a caller-supplied cap.

The primary reference enumerates exponent profiles. The independent reference
sieves divisor counts for every integer through `limit` and returns the first
matching value. The workload includes known A005179 terms, exact cap boundaries,
valid capped misses, and malformed input. See [INVENTORY.md](INVENTORY.md).

The task definition is the sequence “smallest number with exactly `n`
divisors,” [OEIS A005179](https://oeis.org/A005179), also presented by the
[Rosetta Code task](https://rosettacode.org/wiki/Sequence:_smallest_number_with_exactly_n_divisors).
The exponent-profile search follows the divisor-count identity and the
factorization characterization recorded in the [OEIS entry](https://oeis.org/A005179/internal).
Only the mathematical idea and sequence definition were consulted; the
benchmark contract, code, references, fixtures, and prose are independently
authored. See [RIGHTS.md](RIGHTS.md).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/smallest_number_with_n_divisors.c](../../../c/s/smallest_number_with_n_divisors.c) |
| C3 | [c3/s/smallest_number_with_n_divisors.c3](../../../c3/s/smallest_number_with_n_divisors.c3) |
| C++ | [cpp/s/smallest_number_with_n_divisors.cpp](../../../cpp/s/smallest_number_with_n_divisors.cpp) |
| Elisa | [elisa/s/smallest_number_with_n_divisors.elisa](../../../elisa/s/smallest_number_with_n_divisors.elisa) |
| Mojo | [mojo/s/smallest_number_with_n_divisors.mojo](../../../mojo/s/smallest_number_with_n_divisors.mojo) |
| Nim | [nim/s/smallest_number_with_n_divisors.nim](../../../nim/s/smallest_number_with_n_divisors.nim) |
| Odin | [odin/s/smallest_number_with_n_divisors.odin](../../../odin/s/smallest_number_with_n_divisors.odin) |
| Rust | [rust/s/smallest_number_with_n_divisors.rs](../../../rust/s/smallest_number_with_n_divisors.rs) |
| V | [v/s/smallest_number_with_n_divisors.v](../../../v/s/smallest_number_with_n_divisors.v) |
| Zig | [zig/s/smallest_number_with_n_divisors.zig](../../../zig/s/smallest_number_with_n_divisors.zig) |
