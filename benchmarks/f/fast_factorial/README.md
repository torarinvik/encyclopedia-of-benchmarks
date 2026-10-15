# Fast Factorial

## Contract

Compute `n!` for inputs from 0 through 20 and return the exact signed 64-bit result. Inputs outside that range return `-1`. The bound keeps every intermediate product and the final result within the shared scalar ABI; `20!` is the largest supported value.

The exported function is:

```c
int64_t fast_factorial(int64_t n);
```

The implementation preserves the pinned Rust algorithm's structure: sieve primes through `n`, compute each prime's exponent in `n!` as `floor(n/p) + floor(n/p²) + ...`, split those exponents into binary bit buckets, then multiply the bucket products raised to powers of two. The final powers use exponentiation by squaring. This differs from the iterative factor loop in the separate [`factorial`](../factorial/README.md) benchmark.

The upstream source returns an arbitrary precision `BigUint`; this benchmark uses the safe `0..=20` subdomain so all nine ports can use the same signed 64-bit ABI while preserving its prime-sieve and balanced-product method.

## Workload

[`workload.json`](workload.json) covers base cases, prime and composite values, several exponent-bit patterns, the maximum supported input, and both range boundaries. The runner compares scalar results before timing.

## Pinned source

- Rust [`fast_factorial.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/big_integer/fast_factorial.rs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fast_factorial.c`](../../../c/f/fast_factorial.c) |
| C3 | [`c3/f/fast_factorial.c3`](../../../c3/f/fast_factorial.c3) |
| C++ | [`cpp/f/fast_factorial.cpp`](../../../cpp/f/fast_factorial.cpp) |
| Elisa | [`elisa/f/fast_factorial.elisa`](../../../elisa/f/fast_factorial.elisa) |
| Nim | [`nim/f/fast_factorial.nim`](../../../nim/f/fast_factorial.nim) |
| Odin | [`odin/f/fast_factorial.odin`](../../../odin/f/fast_factorial.odin) |
| Rust | [`rust/f/fast_factorial.rs`](../../../rust/f/fast_factorial.rs) |
| V | [`v/f/fast_factorial.v`](../../../v/f/fast_factorial.v) |
| Zig | [`zig/f/fast_factorial.zig`](../../../zig/f/fast_factorial.zig) |
