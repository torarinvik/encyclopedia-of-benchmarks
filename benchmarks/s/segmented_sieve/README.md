# Segmented sieve

This package ports the pinned [TheAlgorithms/Python segmented sieve](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/segmented_sieve.py). It first sieves base primes through `floor(sqrt(n))`, then marks composite values in consecutive segments and returns every prime not exceeding `n` in ascending order.

The `i64_array_bytes_output` ABI accepts exactly one value `[n]`, with `2 <= n <= 10,000`. The output is a packed sequence of signed 64-bit prime values in little-endian byte order. Invalid input returns `-1`; insufficient output capacity returns `-2`; success returns eight times the number of primes found.

This package preserves the source's segmented sieve strategy; its largest supported result has 1,229 primes. Runtime is `O(n log log n)` and auxiliary space is `O(sqrt(n))` for the base sieve plus the current segment.

## Workload

[`workload.json`](workload.json) covers the source examples, small bounds, a mid-size sieve, the maximum supported input, and invalid layouts/bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/segmented_sieve.c`](../../../c/s/segmented_sieve.c) |
| C3 | [`c3/s/segmented_sieve.c3`](../../../c3/s/segmented_sieve.c3) |
| C++ | [`cpp/s/segmented_sieve.cpp`](../../../cpp/s/segmented_sieve.cpp) |
| Elisa | [`elisa/s/segmented_sieve.elisa`](../../../elisa/s/segmented_sieve.elisa) |
| Nim | [`nim/s/segmented_sieve.nim`](../../../nim/s/segmented_sieve.nim) |
| Odin | [`odin/s/segmented_sieve.odin`](../../../odin/s/segmented_sieve.odin) |
| Rust | [`rust/s/segmented_sieve.rs`](../../../rust/s/segmented_sieve.rs) |
| V | [`v/s/segmented_sieve.v`](../../../v/s/segmented_sieve.v) |
| Zig | [`zig/s/segmented_sieve.zig`](../../../zig/s/segmented_sieve.zig) |
