# Kaprekar numbers in a range

Enumerate every Kaprekar number in an inclusive decimal interval, preserving the pinned Java utility's ascending list result and its special inclusion of zero. This package is separate from [`kaprekar_number`](../kaprekar_number/README.md), which checks one input value.

## Contract

- Input is `[start_inclusive, end_inclusive]`, with `0 <= start <= end <= 100,000`. Invalid ranges return `-1`.
- The range method tests each integer using the Java class's Kaprekar predicate. `0` and `1` are included as Kaprekar values. For values above one, the square is split so the right part has the same decimal width as the value; that part must be nonzero and the two parts must sum to the input.
- The returned list is encoded as ascending decimal values, each followed by a NUL byte. The function returns the number of output bytes; insufficient capacity returns `-2`.
- The bound keeps every square within signed 64-bit range and limits enumeration cost.

## Workload

[`workload.json`](workload.json) covers the zero and one special cases, known values, an empty result range, an inclusive endpoint, the upper bound, and invalid ranges.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kaprekar_numbers_in_range.c`](../../../c/k/kaprekar_numbers_in_range.c) |
| C3 | [`c3/k/kaprekar_numbers_in_range.c3`](../../../c3/k/kaprekar_numbers_in_range.c3) |
| C++ | [`cpp/k/kaprekar_numbers_in_range.cpp`](../../../cpp/k/kaprekar_numbers_in_range.cpp) |
| Elisa | [`elisa/k/kaprekar_numbers_in_range.elisa`](../../../elisa/k/kaprekar_numbers_in_range.elisa) |
| Nim | [`nim/k/kaprekar_numbers_in_range.nim`](../../../nim/k/kaprekar_numbers_in_range.nim) |
| Odin | [`odin/k/kaprekar_numbers_in_range.odin`](../../../odin/k/kaprekar_numbers_in_range.odin) |
| Rust | [`rust/k/kaprekar_numbers_in_range.rs`](../../../rust/k/kaprekar_numbers_in_range.rs) |
| V | [`v/k/kaprekar_numbers_in_range.v`](../../../v/k/kaprekar_numbers_in_range.v) |
| Zig | [`zig/k/kaprekar_numbers_in_range.zig`](../../../zig/k/kaprekar_numbers_in_range.zig) |

## Pinned source

- [TheAlgorithms Java `KaprekarNumbers.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/KaprekarNumbers.java)
