# One Bit Difference

This benchmark ports Java `OneBitDifference.differByOneBit(int, int)`. It returns true only when the two signed 32-bit integers differ in exactly one bit. Equal values return false; the source computes XOR and tests whether the nonzero difference has a single set bit.

## Contract

- The `i64_array_scalar` input is exactly `[left, right]`; both values must be in Java's signed 32-bit integer range.
- The result is `1` when the 32-bit two's-complement bit patterns differ in exactly one bit, otherwise `0`. This includes the sign bit; for example, `0` and `INT32_MIN` differ by one bit.
- Missing, extra, or out-of-range inputs return `-1`. The parser accepts up to three values so the one-extra-value malformed case reaches the ABI.
- Ports use unsigned 32-bit XOR and clear-lowest-set-bit arithmetic to avoid signed overflow at `INT32_MIN`.

## Pinned source

- Java [`OneBitDifference.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/OneBitDifference.java)

## Workload and build

[`workload.json`](workload.json) covers equal and unequal inputs, one and multiple differing bits, negative values, and signed 32-bit boundaries. The independent oracle is [`one_bit_difference_oracle.py`](../../one_bit_difference_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm one_bit_difference --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/o/one_bit_difference/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms one_bit_difference
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/one_bit_difference.c`](../../../c/o/one_bit_difference.c) |
| C3 | [`c3/one_bit_difference.c3`](../../../c3/o/one_bit_difference.c3) |
| C++ | [`cpp/one_bit_difference.cpp`](../../../cpp/o/one_bit_difference.cpp) |
| Elisa | [`elisa/one_bit_difference.elisa`](../../../elisa/o/one_bit_difference.elisa) |
| Nim | [`nim/one_bit_difference.nim`](../../../nim/o/one_bit_difference.nim) |
| Odin | [`odin/one_bit_difference.odin`](../../../odin/o/one_bit_difference.odin) |
| Rust | [`rust/one_bit_difference.rs`](../../../rust/o/one_bit_difference.rs) |
| V | [`v/one_bit_difference.v`](../../../v/o/one_bit_difference.v) |
| Zig | [`zig/one_bit_difference.zig`](../../../zig/o/one_bit_difference.zig) |
