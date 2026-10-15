# Hardy–Ramanujan prime-factor count

This benchmark follows the executable `exact_prime_factor_count` function in the pinned Python file. Despite the candidate name, that function computes the exact number of **distinct prime divisors** of its input.

## Contract

- The unary `scalar` ABI accepts a signed 64-bit integer `n` in `1..=2,147,483,647`.
- Return the number of distinct primes dividing `n`; return zero for `n=1`.
- Inputs outside this positive signed-32-bit domain return `-1`.

The implementation first counts and removes the factor 2, then tests odd divisors beginning at 3. When a divisor divides the current remainder, it increments the count once and divides out every copy. A remaining value greater than 2 contributes one final prime divisor. The loop condition `factor <= remaining / factor` is the integer equivalent of the source's `factor <= int(sqrt(remaining))` check.

The upper bound keeps the source's `int(n / factor)` conversions exact whenever the division is taken: the quotient is an integer no larger than the signed 32-bit maximum, so binary64 represents it exactly. The positive lower bound also excludes zero, which would remain zero in the source's factor-2 division loop.

This returns a count, rather than factor data. [`prime_factors`](../../p/prime_factors/README.md) and [`prime_factorization`](../../p/prime_factorization/README.md) return factor representations; [`liouville_lambda`](../../l/liouville_lambda/README.md) uses the parity of the total factor count with multiplicity; and [`mobius_function`](../../m/mobius_function/README.md) returns squarefree parity.

## Source and workload

The pinned [Python `hardy_ramanujanalgo.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/hardy_ramanujanalgo.py) defines `exact_prime_factor_count` using the factor-2 pass, odd trial divisors, and a final remaining-prime check. Its returned value is not an approximation of the Hardy–Ramanujan average.

[`workload.json`](workload.json) covers one, primes, repeated factors, mixed composites, the upper bound, and invalid input values. The package uses the unary signed 64-bit scalar ABI.

| Language | Source |
| --- | --- |
| C | [`c/h/hardy_ramanujanalgo.c`](../../../c/h/hardy_ramanujanalgo.c) |
| C3 | [`c3/h/hardy_ramanujanalgo.c3`](../../../c3/h/hardy_ramanujanalgo.c3) |
| C++ | [`cpp/h/hardy_ramanujanalgo.cpp`](../../../cpp/h/hardy_ramanujanalgo.cpp) |
| Elisa | [`elisa/h/hardy_ramanujanalgo.elisa`](../../../elisa/h/hardy_ramanujanalgo.elisa) |
| Nim | [`nim/h/hardy_ramanujanalgo.nim`](../../../nim/h/hardy_ramanujanalgo.nim) |
| Odin | [`odin/h/hardy_ramanujanalgo.odin`](../../../odin/h/hardy_ramanujanalgo.odin) |
| Rust | [`rust/h/hardy_ramanujanalgo.rs`](../../../rust/h/hardy_ramanujanalgo.rs) |
| V | [`v/h/hardy_ramanujanalgo.v`](../../../v/h/hardy_ramanujanalgo.v) |
| Zig | [`zig/h/hardy_ramanujanalgo.zig`](../../../zig/h/hardy_ramanujanalgo.zig) |
