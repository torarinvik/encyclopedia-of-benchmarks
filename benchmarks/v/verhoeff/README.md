# Verhoeff checksum validation

This benchmark validates a decimal digit sequence with the Verhoeff checksum algorithm.

## Contract

- The input is an array of 1 through 1024 signed 64-bit digit values. Every value must be in `0..=9`.
- Leading zeros are significant and remain part of the sequence.
- Return `1` when the Verhoeff checksum is valid and `0` otherwise. Empty or malformed inputs and arrays longer than 1024 return `-1`.
- The ports use the multiplication and permutation tables from the pinned Java implementation. They process digits from right to left, cycling through the eight permutation rows.

The pinned Java `verhoeffCheck(String)` rejects empty strings and any character outside decimal digits, then returns whether the accumulated checksum is zero. The benchmark maps the string to its exact digit sequence, preserving leading zeros.

## Inspected upstream source

- [Java — `Verhoeff.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/Verhoeff.java)

Build and record with the `i64_array_scalar` ABI family. Implementations are in `v/` in all nine language directories.
