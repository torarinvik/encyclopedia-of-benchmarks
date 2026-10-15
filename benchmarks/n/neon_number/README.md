# Neon number

A neon number is a nonnegative integer equal to the sum of the decimal digits of its square. The implementations sum digits with integer division and remainder, matching the pinned PHP source's decimal-string operation.

## Contract

- Input is a signed 64-bit integer. Negative inputs return `0`, matching the source's comparison behavior. Nonnegative inputs through `3,000,000,000` are accepted; larger values return `-1`.
- Return `1` exactly when the sum of the digits of `n²` equals `n`; otherwise return `0`. Zero is neon because its square has the single digit zero.
- The upper bound keeps `n²` within signed 64-bit range (`3,000,000,000² = 9,000,000,000,000,000,000`).

The benchmark follows the pinned [TheAlgorithms PHP source `Maths/NeonNumber.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/NeonNumber.php). It squares the input, sums the square's decimal digits, then compares the sum with the input. The benchmark expresses inputs above the portable square bound as invalid `-1` results.

[`workload.json`](workload.json) covers zero, known neon values, nonmatches, negative inputs, and the upper bound. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm neon_number --language c
python3 benchmarks/run_scalar.py --algorithm neon_number
```

Implementations: `c/n/neon_number.c`, `c3/n/neon_number.c3`, `cpp/n/neon_number.cpp`, `elisa/n/neon_number.elisa`, `nim/n/neon_number.nim`, `odin/n/neon_number.odin`, `rust/n/neon_number.rs`, `v/n/neon_number.v`, and `zig/n/neon_number.zig`.
