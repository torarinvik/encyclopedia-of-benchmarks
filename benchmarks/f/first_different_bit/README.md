# First different bit

Returns the zero-based index of the least significant bit where two signed 32-bit integers differ.

## Contract

- Uses the `binary_scalar` ABI with arguments `[x, y]`.
- Each input must be in the signed 32-bit range.
- Interpret inputs as 32-bit two's-complement bit patterns, XOR them, and count trailing zero bits.
- The result is in `0..32`; equal inputs return `32`, matching Java's `Integer.numberOfTrailingZeros(0)` behavior.
- Invalid values outside signed 32-bit range return `-1`.

## Source semantics

This follows the pinned [TheAlgorithms Java `FirstDifferentBit.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/FirstDifferentBit.java). The source computes `x ^ y` and applies `Integer.numberOfTrailingZeros`; the Java `int` width makes the equal-input result exactly 32. Negative values use their ordinary 32-bit two's-complement representation.

This is a two-input differing-bit operation. It differs from one-input least-significant-set-bit position benchmarks and from trailing-zero count over an input value: it counts zeros in the XOR of the pair.

## Workload and build

[`workload.json`](workload.json) covers low and high differing positions, negative values, equal inputs, signed boundaries, and invalid values. Build and record with the binary scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm first_different_bit --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/f/first_different_bit/rust/build.json
```

The nine implementations are in `c/f/first_different_bit.c`, `c3/f/first_different_bit.c3`, `cpp/f/first_different_bit.cpp`, `elisa/f/first_different_bit.elisa`, `nim/f/first_different_bit.nim`, `odin/f/first_different_bit.odin`, `rust/f/first_different_bit.rs`, `v/f/first_different_bit.v`, and `zig/f/first_different_bit.zig`.
