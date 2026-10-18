# Greatest prime factor

Return the largest prime factor of a nonnegative integer, following the pinned
Python `primelib` implementation.

## Contract

- The unary scalar input is a signed 64-bit integer `n` in `0..=1,000,000`.
- For `n >= 2`, return its greatest prime factor.
- Preserve the source's defined edge results: `greatest_prime_factor(0) = 0`
  and `greatest_prime_factor(1) = 1`. The source first returns `[n]` from
  `prime_factorization` for either input, then applies `max` to that list.
- Return `-1` for negative inputs and values above the bound. Negative inputs
  trigger a source assertion; the bounded ABI represents that and the workload
  bound with the same invalid-input result.

The source obtains repeated prime factors in ascending order, then returns the
maximum. The one-million upper bound keeps its repeated trial-division calls
practical while allowing nontrivial prime powers and semiprimes.
The local ports preserve the source's prime-input shortcut and ascending
candidate scan: each candidate is checked for primality before it divides the
remaining quotient, and the last factor found is the result.

## Workload

[`workload.json`](workload.json) includes the source's 0 and 1 edge results,
small primes and composites, repeated factors, a large semiprime, the maximum
input, and invalid signed boundaries. The independent
[`greatest_prime_factor_oracle.py`](../../greatest_prime_factor_oracle.py)
uses repeated division and tracks the largest factor; it does not call the
source's primality or factorization helpers.

The scalar ABI entry point is:

```c
int64_t greatest_prime_factor(int64_t n);
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/greatest_prime_factor.c`](../../../c/g/greatest_prime_factor.c) |
| C3 | [`c3/g/greatest_prime_factor.c3`](../../../c3/g/greatest_prime_factor.c3) |
| C++ | [`cpp/g/greatest_prime_factor.cpp`](../../../cpp/g/greatest_prime_factor.cpp) |
| Elisa | [`elisa/g/greatest_prime_factor.elisa`](../../../elisa/g/greatest_prime_factor.elisa) |
| Nim | [`nim/g/greatest_prime_factor.nim`](../../../nim/g/greatest_prime_factor.nim) |
| Odin | [`odin/g/greatest_prime_factor.odin`](../../../odin/g/greatest_prime_factor.odin) |
| Rust | [`rust/g/greatest_prime_factor.rs`](../../../rust/g/greatest_prime_factor.rs) |
| V | [`v/g/greatest_prime_factor.v`](../../../v/g/greatest_prime_factor.v) |
| Zig | [`zig/g/greatest_prime_factor.zig`](../../../zig/g/greatest_prime_factor.zig) |

## Pinned source

- [Python `primelib.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/primelib.py), especially `greatest_prime_factor` and `prime_factorization`.
