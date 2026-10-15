# Numbers with different signs

Checks the sign bit of the bitwise XOR of two signed 32-bit integers. The result is a boolean encoded as an integer.

## Contract

- Uses the `binary_scalar` ABI with arguments `[left, right]`.
- Both inputs must fit signed 32-bit range.
- Return `1` if `(left XOR right) < 0`; otherwise return `0`.
- Return `-1` if either input is outside signed 32-bit range.
- Zero follows the source's bitwise rule: zero with a negative value returns `1`, while zero with a nonnegative value returns `0`.

## Source semantics

This follows pinned [TheAlgorithms Java `NumbersDifferentSigns.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/NumbersDifferentSigns.java) and [Python `numbers_different_signs.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/numbers_different_signs.py). Both return whether the XOR of the operands is negative. Java uses signed 32-bit integers; Python integers are unbounded, so the shared contract uses their common signed 32-bit input domain. The ports preserve the source predicate exactly, including its result for zero paired with a negative operand.

## Workload and build

[`workload.json`](workload.json) covers same-sign and mixed-sign pairs, zero, signed boundaries, and invalid operands. Build and record with the binary scalar ABI:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm numbers_different_signs --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/n/numbers_different_signs/rust/build.json
```

The nine implementations are in `c/n/numbers_different_signs.c`, `c3/n/numbers_different_signs.c3`, `cpp/n/numbers_different_signs.cpp`, `elisa/n/numbers_different_signs.elisa`, `nim/n/numbers_different_signs.nim`, `odin/n/numbers_different_signs.odin`, `rust/n/numbers_different_signs.rs`, `v/n/numbers_different_signs.v`, and `zig/n/numbers_different_signs.zig`.
