# Binary Addition

Add two binary strings with a right-to-left carry pass. The C++, Java, and TypeScript candidates share this mathematical contract for valid binary strings; this is one benchmark, with `add_binary` recorded as an alias of `binary_addition`.

## Contract

- Each operand is a string of zero through 2,047 binary digits. The empty string represents zero and adding two empty strings returns an empty result.
- The ABI packs the two operands as `[first_length, second_length, first_bits..., second_bits...]`; each bit is the integer `0` or `1`.
- The result is returned as ASCII bytes containing `0` and `1`.
- The result keeps leading zeroes from the longer operand. A final carry adds one more leading bit.
- Malformed packed input or a non-binary digit returns `-1`. A missing or undersized output buffer returns `-2`; errors leave the output unchanged.

For example, `00101 + 1` returns `00110`, and `1111 + 1111` returns `11110`. The shared contract defines behavior for malformed strings consistently; the TypeScript source does not validate them and the Java source treats non-`1` characters as zero, while the C++ source rejects them.

## Workload and verification

[`workload.json`](workload.json) covers empty operands, unequal lengths, carry propagation, leading zeroes, invalid packed arrays, and maximum-width operands. [`benchmarks/verify_binary_addition.py`](../../verify_binary_addition.py) compares all nine ports against a separate integer-arithmetic oracle over exhaustive short strings, deterministic randomized inputs, malformed inputs, and every workload record.

## Reviewed TheAlgorithms sources

- [C++ `binary_addition.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/binary_addition.cpp)
- [Java `BinaryAddition.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/BinaryAddition.java)
- [TypeScript `add_binary.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/bit_manipulation/add_binary.ts)

## Build

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
