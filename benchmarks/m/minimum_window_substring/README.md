# Minimum window substring

The pinned Java `MinimumWindowSubstring.minWindow` and Python `min_window` implementations use sliding windows and frequency counts to find the shortest substring containing every requested character with multiplicity. The Python source has the same result on this benchmark's ASCII domain. Both keep the earliest window among equal-length results.

## Contract

Input is `[search_length, search_ascii..., target_length, target_ascii...]` as signed 64-bit values in the byte-output ABI. Search and target lengths are at most 128; target length is at least one; bytes are ASCII 0 through 127. A successful call returns the byte length of the shortest matching substring (zero if no match) and writes its ASCII bytes. Malformed input returns `-1`; insufficient capacity returns `-2`. A minimum-length tie returns the earliest substring.

The bound makes the exact-length format fit within 258 i64 values. The Java source's `s.length() < t.length()` fast path, frequency-count sliding window, and earliest tie behavior are preserved. The pinned Python source uses the same multiplicity-aware window; empty-target behavior is excluded because the Java source does not handle it safely.

Pinned sources: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/MinimumWindowSubstring.java) and [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/min_window_substring.py). [`workload.json`](workload.json) covers repeated requirements, ties, absent targets, and malformed input. Runtime oracle: [`benchmarks/minimum_window_substring_oracle.py`](../../minimum_window_substring_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/minimum_window_substring.c`](../../../c/m/minimum_window_substring.c) |
| C3 | [`c3/m/minimum_window_substring.c3`](../../../c3/m/minimum_window_substring.c3) |
| C++ | [`cpp/m/minimum_window_substring.cpp`](../../../cpp/m/minimum_window_substring.cpp) |
| Elisa | [`elisa/m/minimum_window_substring.elisa`](../../../elisa/m/minimum_window_substring.elisa) |
| Nim | [`nim/m/minimum_window_substring.nim`](../../../nim/m/minimum_window_substring.nim) |
| Odin | [`odin/m/minimum_window_substring.odin`](../../../odin/m/minimum_window_substring.odin) |
| Rust | [`rust/m/minimum_window_substring.rs`](../../../rust/m/minimum_window_substring.rs) |
| V | [`v/m/minimum_window_substring.v`](../../../v/m/minimum_window_substring.v) |
| Zig | [`zig/m/minimum_window_substring.zig`](../../../zig/m/minimum_window_substring.zig) |
