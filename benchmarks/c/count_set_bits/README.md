# Count set bits

Counts the total number of set bits in the binary representations of all integers from 1 through `n`, inclusive. This is a prefix total, rather than the popcount of a single input.

## Contract

- Uses the unary scalar ABI: `int64_t count_set_bits(int64_t n)`.
- Valid inputs are `0 <= n <= 67,108,863` (`2^26 - 1`). The maximum result is `26 * 2^25 = 872,415,232`, which fits the source's signed 32-bit result type.
- Return zero for `n = 0`; otherwise return the total set-bit count over `1..=n`.
- Return `-1` for inputs outside the bounded domain. The pinned source throws for negative values; the sentinel maps invalid ABI inputs.

## Source semantics and integer bound

This benchmark follows the recursive formula in the pinned [TheAlgorithms Java `CountSetBits.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/CountSetBits.java). For `n > 0`, let `x` be the position of its highest set bit and `p = 2^x`. The source computes `x * 2^(x-1) + (n - p + 1) + countSetBits(n - p)`. When `x = 0`, the ports state the zero first term directly.

The pinned helper `largestPowerOf2InNumber` searches with `while ((1 << position) <= n)`. Java masks an `int` shift count modulo 32, so the helper can cycle once inputs reach `2^30` and the shift reaches position 31. The benchmark cap `2^26 - 1` stays below that region; the ports use an overflow-safe highest-power search and retain the recursive formula on the supported domain. This bound also keeps intermediate and final results within signed 32-bit range.

This is distinct from [`hamming_weight`](../../h/hamming_weight/README.md), which returns the set-bit count for one unsigned 32-bit value.

## Workload and build

[`workload.json`](workload.json) covers zero, small prefixes, exact powers of two, the configured upper bound, negative input, and an input above the declared bound. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm count_set_bits --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/c/count_set_bits/rust/build.json
```

The nine implementations are in `c/c/count_set_bits.c`, `c3/c/count_set_bits.c3`, `cpp/c/count_set_bits.cpp`, `elisa/c/count_set_bits.elisa`, `nim/c/count_set_bits.nim`, `odin/c/count_set_bits.odin`, `rust/c/count_set_bits.rs`, `v/c/count_set_bits.v`, and `zig/c/count_set_bits.zig`.
