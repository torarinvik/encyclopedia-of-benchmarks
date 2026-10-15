# Alphabetical string check

Check whether a nonempty string consists only of letters whose lowercase forms are in nondecreasing order.

## Contract

- The `i64_array_scalar` ABI represents the string as one ASCII value per element. Lengths 0 through 256 are supported.
- ASCII letters `A-Z` and `a-z` are allowed; comparison is case-insensitive and equal adjacent letters are allowed. Empty strings and strings containing nonletters return `0`.
- A length over 256 or a value outside `[0,127]` returns `-1`. Unicode letters are outside this bounded benchmark contract.

## Source semantics

This follows the pinned [TheAlgorithms Java `Alphabetical.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Alphabetical.java). The Java method rejects null or blank strings and nonletters, lowercases with `Locale.ROOT`, then checks nondecreasing character order. The benchmark preserves that behavior on ASCII strings; its byte-value error sentinel and maximum length are ABI bounds.

## Workload

[`workload.json`](workload.json) covers sorted and unsorted strings, case folding, duplicate letters, empty input, nonletters, invalid byte values, and the maximum length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/alphabetical.c`](../../../c/a/alphabetical.c) |
| C3 | [`c3/a/alphabetical.c3`](../../../c3/a/alphabetical.c3) |
| C++ | [`cpp/a/alphabetical.cpp`](../../../cpp/a/alphabetical.cpp) |
| Elisa | [`elisa/a/alphabetical.elisa`](../../../elisa/a/alphabetical.elisa) |
| Nim | [`nim/a/alphabetical.nim`](../../../nim/a/alphabetical.nim) |
| Odin | [`odin/a/alphabetical.odin`](../../../odin/a/alphabetical.odin) |
| Rust | [`rust/a/alphabetical.rs`](../../../rust/a/alphabetical.rs) |
| V | [`v/a/alphabetical.v`](../../../v/a/alphabetical.v) |
| Zig | [`zig/a/alphabetical.zig`](../../../zig/a/alphabetical.zig) |

Build and record with the array-scalar ABI: `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm alphabetical --language c`.
