# Reverse a nonnegative integer

Reverse the decimal digits of a nonnegative integer by repeatedly extracting its last digit.

## Contract

- The scalar input is an integer in `[0, 1,000,000,000]`.
- Repeatedly compute `reversed = reversed * 10 + number % 10`, then divide `number` by 10 using integer division.
- Return `0` for input `0`. Leading zeroes in the reversed representation are naturally discarded.
- Inputs outside the range return `-1`.

The bound keeps the result within signed 32-bit range, so both pinned Java and JavaScript implementations return the same integer without overflow or floating-point rounding. The common contract excludes negatives: Java throws for them, while JavaScript's loop returns zero. JavaScript inputs are numbers, but the benchmark uses integral values only, matching Java's `int` parameter.

## Workload and implementations

[`workload.json`](workload.json) covers zero, one-digit values, trailing zeroes, representative multi-digit values, the maximum input, and invalid boundaries. The package uses the scalar ABI.

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_number.c`](../../../c/r/reverse_number.c) |
| C3 | [`c3/r/reverse_number.c3`](../../../c3/r/reverse_number.c3) |
| C++ | [`cpp/r/reverse_number.cpp`](../../../cpp/r/reverse_number.cpp) |
| Elisa | [`elisa/r/reverse_number.elisa`](../../../elisa/r/reverse_number.elisa) |
| Nim | [`nim/r/reverse_number.nim`](../../../nim/r/reverse_number.nim) |
| Odin | [`odin/r/reverse_number.odin`](../../../odin/r/reverse_number.odin) |
| Rust | [`rust/r/reverse_number.rs`](../../../rust/r/reverse_number.rs) |
| V | [`v/r/reverse_number.v`](../../../v/r/reverse_number.v) |
| Zig | [`zig/r/reverse_number.zig`](../../../zig/r/reverse_number.zig) |

## Pinned sources

- [TheAlgorithms Java `ReverseNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ReverseNumber.java)
- [TheAlgorithms JavaScript `ReverseNumber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ReverseNumber.js)
