# Perfect numbers

## Contract

Input is the one-element signed 64-bit array `[n]`, where `0 <= n <= 1,000,000,000`. Return `1` when `n` is a perfect number (the sum of its positive proper divisors equals `n`), and `0` otherwise. Values outside the domain or arrays with any other length return `-1`.

The predicate visits divisor pairs through `sqrt(n)`. It starts with divisor sum 1 for `n > 1`; when a divisor is found, it adds both members of the pair, avoiding double-counting a square root. Values zero and one are non-perfect.

## Source review

The pinned F# `isPerfect` function rejects nonpositive inputs and scans divisor pairs up to the square root, then compares the sum to `2*n` (the sum includes `n` itself). Its pair formula counts the square-root divisor twice when `n` is a square; the benchmark uses the standard proper-divisor sum and records this edge discrepancy. Rust exposes the same predicate as part of its `perfect_numbers(max)` enumeration, though its divisor scan is linear. The AArch64 assembly generates even perfect numbers from Mersenne primes using the Euclid–Euler formula rather than testing each input; that source has a distinct implementation strategy and is noted as such. The benchmark bounds arithmetic to signed 64-bit safety.

Pinned sources: [F# `Perfect_Numbers.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Math/Perfect_Numbers.fs), [Rust `perfect_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/perfect_numbers.rs), and [AArch64 `perfect_numbers.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/misc/perfect_numbers.s).

## Workload and implementations

[`workload.json`](workload.json) covers zero and one, prime and composite non-perfect values, the first four perfect numbers, and invalid bounds. The [runtime oracle](../../perfect_numbers_oracle.py) implements the contract above.

| Language | Port |
|---|---|
| C | [`c/p/perfect_numbers.c`](../../../c/p/perfect_numbers.c) |
| C3 | [`c3/p/perfect_numbers.c3`](../../../c3/p/perfect_numbers.c3) |
| C++ | [`cpp/p/perfect_numbers.cpp`](../../../cpp/p/perfect_numbers.cpp) |
| Elisa | [`elisa/p/perfect_numbers.elisa`](../../../elisa/p/perfect_numbers.elisa) |
| Nim | [`nim/p/perfect_numbers.nim`](../../../nim/p/perfect_numbers.nim) |
| Odin | [`odin/p/perfect_numbers.odin`](../../../odin/p/perfect_numbers.odin) |
| Rust | [`rust/p/perfect_numbers.rs`](../../../rust/p/perfect_numbers.rs) |
| V | [`v/p/perfect_numbers.v`](../../../v/p/perfect_numbers.v) |
| Zig | [`zig/p/perfect_numbers.zig`](../../../zig/p/perfect_numbers.zig) |
