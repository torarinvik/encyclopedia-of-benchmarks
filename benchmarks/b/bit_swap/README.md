# Bit swap

This benchmark swaps the bits at two selected positions in a signed 32-bit integer, using 0-based positions counted from the least significant bit.

## Contract

- The `i64_array_scalar` input is exactly `[data, posA, posB]`.
- `data` must be in the signed 32-bit range, and both bit positions must be in `[0, 31]`.
- If the selected bits differ, they are exchanged; if they match, `data` is unchanged. The output is the resulting signed 32-bit value sign-extended to signed 64-bit.
- Malformed arrays, values outside signed int32, or invalid positions map to `-2147483649` in the benchmark ABI, outside the signed int32 result range. The Java source throws for invalid positions; the other invalid mappings are benchmark bounds.

The source uses Java's arithmetic right shift to inspect bits and XOR masks to exchange different bits. The portable ports reproduce the 32-bit result explicitly, including negative inputs and position 31. This is a selected-position operation, distinct from swapping all adjacent bit pairs. Source: [Java `BitSwap`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/BitSwap.java).

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
