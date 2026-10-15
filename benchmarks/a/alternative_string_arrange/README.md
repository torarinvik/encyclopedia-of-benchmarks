# Alternative string arrange

Merge two strings by taking one character from the first, then one from the second, repeating until both are exhausted. Any remaining suffix is appended in order.

## Contract

- The `i64_array_bytes_output` ABI accepts `[lengthA, lengthB, charsA..., charsB...]` and returns the merged ASCII bytes.
- Each string has 0 through 64 ASCII code points (0 through 127). Characters from the first string appear before the corresponding character from the second.
- Empty strings are allowed. Two empty strings produce empty output.
- Malformed packed lengths or non-ASCII values return `-1`; insufficient output capacity returns `-2`.
- Results are compared byte for byte.

## Source semantics

This follows pinned [TheAlgorithms Java `AlternativeStringArrange`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/AlternativeStringArrange.java), [JavaScript `AlternativeStringArrange.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/AlternativeStringArrange.js), and [Python `alternative_string_arrange.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/alternative_string_arrange.py). All three alternate by character index and append the unpaired tail. The benchmark restricts inputs to ASCII so Java UTF-16 units and Python Unicode code points have the same representation as JavaScript string indices for every valid input; null and non-string inputs are outside the packed ABI.

## Workload

[`workload.json`](workload.json) includes the Java and Python examples, equal and empty inputs, and invalid packed layouts.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/alternative_string_arrange.c`](../../../c/a/alternative_string_arrange.c) |
| C3 | [`c3/a/alternative_string_arrange.c3`](../../../c3/a/alternative_string_arrange.c3) |
| C++ | [`cpp/a/alternative_string_arrange.cpp`](../../../cpp/a/alternative_string_arrange.cpp) |
| Elisa | [`elisa/a/alternative_string_arrange.elisa`](../../../elisa/a/alternative_string_arrange.elisa) |
| Nim | [`nim/a/alternative_string_arrange.nim`](../../../nim/a/alternative_string_arrange.nim) |
| Odin | [`odin/a/alternative_string_arrange.odin`](../../../odin/a/alternative_string_arrange.odin) |
| Rust | [`rust/a/alternative_string_arrange.rs`](../../../rust/a/alternative_string_arrange.rs) |
| V | [`v/a/alternative_string_arrange.v`](../../../v/a/alternative_string_arrange.v) |
| Zig | [`zig/a/alternative_string_arrange.zig`](../../../zig/a/alternative_string_arrange.zig) |

The package uses the `i64_array_bytes_output` benchmark ABI.
