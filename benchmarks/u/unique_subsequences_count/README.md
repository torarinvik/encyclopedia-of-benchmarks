# Unique subsequences count

Count the distinct nonempty subsequences of an ASCII string. A subsequence keeps the original character order while allowing characters to be skipped. Repeated characters do not create duplicate subsequences. The empty string has zero nonempty subsequences.

## Contract

- The `i64_array_scalar` input is `[n, ASCII_codepoints...]`, with `n` in `0..=30` and exactly `n` codepoints in `0..=127`.
- Return the number of distinct nonempty subsequences. The maximum result is `2^30 - 1`, which fits the pinned Java method's signed `int` return type.
- Malformed packing, a length outside the bound, or a codepoint outside ASCII returns `-1`.
- Ports evaluate the source recurrence from the end of the string toward the beginning. At each suffix, each distinct next character contributes one single-character subsequence plus the count of subsequences after that character.

## Source and workload

The source is the pinned Java [`UniqueSubsequencesCount.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/UniqueSubsequencesCount.java). Its recursive memoized method returns zero at the end of the string and uses a set at each suffix to count each next character once. This benchmark preserves that recurrence and the count of nonempty subsequences. The ASCII restriction keeps Java character equality aligned with the byte-valued ABI.

[`workload.json`](workload.json) includes empty, singleton, repeated-character, mixed, embedded-NUL, maximum-length, and invalid inputs. This count is distinct from enumerating subsequences or counting positional subsequence selections, where equal character sequences may be produced more than once.

The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

| Language | Source |
| --- | --- |
| C | [`c/u/unique_subsequences_count.c`](../../../c/u/unique_subsequences_count.c) |
| C3 | [`c3/u/unique_subsequences_count.c3`](../../../c3/u/unique_subsequences_count.c3) |
| C++ | [`cpp/u/unique_subsequences_count.cpp`](../../../cpp/u/unique_subsequences_count.cpp) |
| Elisa | [`elisa/u/unique_subsequences_count.elisa`](../../../elisa/u/unique_subsequences_count.elisa) |
| Nim | [`nim/u/unique_subsequences_count.nim`](../../../nim/u/unique_subsequences_count.nim) |
| Odin | [`odin/u/unique_subsequences_count.odin`](../../../odin/u/unique_subsequences_count.odin) |
| Rust | [`rust/u/unique_subsequences_count.rs`](../../../rust/u/unique_subsequences_count.rs) |
| V | [`v/u/unique_subsequences_count.v`](../../../v/u/unique_subsequences_count.v) |
| Zig | [`zig/u/unique_subsequences_count.zig`](../../../zig/u/unique_subsequences_count.zig) |
