# Luhn checksum validation

Validate whether a decimal digit sequence satisfies the Luhn checksum by doubling alternating digits, subtracting nine from doubled values above nine, and summing the adjusted digits.

## Contract

- `i64_array_scalar` input is `[digit_count, digit_0, ..., digit_(digit_count-1)]`.
- Digit count must be even and in 2..64. Packed length must be exactly `digit_count + 1`; each digit must be in 0..9. Leading zeroes are preserved as digits.
- Return 1 when the adjusted sum is divisible by ten and 0 otherwise. Return -1 for malformed lengths, odd counts, or out-of-range digits.

## Source semantics

The pinned Java and Go implementations double even-indexed digits from the left. The C# implementation chooses parity from the total string length, and Python removes the final check digit before walking backward. Those parity rules all agree on even-length digit sequences; odd-length strings are excluded because the four sources do not agree there. The benchmark uses an integer array so every language receives identical decimal digits without string encoding or numeric leading-zero loss.

## Workload

[`workload.json`](workload.json) covers known valid and invalid checksums, leading zeroes, the two-digit boundary, malformed counts, and invalid digit values.

The shared `i64_array_scalar` runner validates the workload by doubling even-indexed digits from the left, applying the Luhn correction, and checking divisibility by ten.

## Pinned sources

- [C# `Luhn.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/Luhn.cs)
- [Go `luhn.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/checksum/luhn.go)
- [Java `Luhn.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/Luhn.java)
- [Python `luhn.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/luhn.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/luhn.c`](../../../c/l/luhn.c) |
| C3 | [`c3/l/luhn.c3`](../../../c3/l/luhn.c3) |
| C++ | [`cpp/l/luhn.cpp`](../../../cpp/l/luhn.cpp) |
| Elisa | [`elisa/l/luhn.elisa`](../../../elisa/l/luhn.elisa) |
| Nim | [`nim/l/luhn.nim`](../../../nim/l/luhn.nim) |
| Odin | [`odin/l/luhn.odin`](../../../odin/l/luhn.odin) |
| Rust | [`rust/l/luhn.rs`](../../../rust/l/luhn.rs) |
| V | [`v/l/luhn.v`](../../../v/l/luhn.v) |
| Zig | [`zig/l/luhn.zig`](../../../zig/l/luhn.zig) |
