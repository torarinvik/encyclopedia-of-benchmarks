# Minimum window subsequence

Find the shortest contiguous window of a search byte sequence in which a pattern occurs as a subsequence. Pattern bytes must appear in order but may have gaps. If several windows have the same minimum length, return the earliest one.

## Contract

- ABI: `i64_array_bytes_output`; input is `[search_length, search_bytes..., pattern_length, pattern_bytes...]` with exact framing.
- Search and pattern lengths are each at most 128; search length may be zero, and pattern length must be at least one. Every byte is an ASCII value from 0 through 127.
- Return the selected window as raw bytes and its byte length. If no window exists, return 0 and write no bytes. Malformed input returns `-1`; a null or undersized output buffer for a nonempty result returns `-2`. Input validation precedes output-buffer validation; a null buffer is accepted when the result is empty.
- The maximum parseable input is 258 signed 64-bit words. The output capacity and algorithm workspace are each at most 128 bytes.

## Method

The primary maintains, for each pattern-prefix length, the latest search index that can start a matching subsequence seen so far. It scans each search byte and updates matching pattern positions in descending order, so one search byte cannot satisfy two pattern positions. At each completed match, the latest possible start gives the shortest window ending there. The algorithm takes `O(nm)` time and `O(m)` bytes of working state, where `n` and `m` are the search and pattern lengths.

The independent reference instead considers each possible endpoint matching the final pattern byte, scans backward greedily for the remaining pattern bytes, and compares the resulting windows. It does not use the prefix-state dynamic program.

This is an episode-matching instance. Das, Fleischer, Gasieniec, Gunopulos, and Kärkkäinen describe minimal text windows containing a pattern as a subsequence in their [CPM 1997 paper](https://citeseerx.ist.psu.edu/document?doi=2457bdf5df84a6f8f39c8e22468d1c0fbe72cdd1&repid=rep1&type=pdf); the [CPM proceedings index](https://cpm.cs.helsinki.fi/cpm97.html) identifies the paper and page range. The LeetCode [sliding-window title index](https://leetcode.com/problem-list/sliding-window/) was used for discovery only. No task statement, example, test, submission, or site code was used.

## Workload and references

- [`workload.json`](workload.json) covers empty and shorter searches, gaps, order-sensitive misses, repeated bytes, earliest-window ties, byte boundaries, malformed framing, and insufficient output capacity.
- [`primary_oracle.py`](primary_oracle.py) implements the latest-start DP.
- [`independent_oracle.py`](independent_oracle.py) uses the backward-greedy scan.
- [`RIGHTS.md`](RIGHTS.md) records provenance and clean-room terms.
- [`check_inventory.py`](check_inventory.py) statically checks the package file inventory.

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/minimum_window_subsequence.c`](../../../c/m/minimum_window_subsequence.c) |
| C3 | [`c3/m/minimum_window_subsequence.c3`](../../../c3/m/minimum_window_subsequence.c3) |
| C++ | [`cpp/m/minimum_window_subsequence.cpp`](../../../cpp/m/minimum_window_subsequence.cpp) |
| Elisa | [`elisa/m/minimum_window_subsequence.elisa`](../../../elisa/m/minimum_window_subsequence.elisa) |
| Mojo | [`mojo/m/minimum_window_subsequence.mojo`](../../../mojo/m/minimum_window_subsequence.mojo) |
| Nim | [`nim/m/minimum_window_subsequence.nim`](../../../nim/m/minimum_window_subsequence.nim) |
| Odin | [`odin/m/minimum_window_subsequence.odin`](../../../odin/m/minimum_window_subsequence.odin) |
| Rust | [`rust/m/minimum_window_subsequence.rs`](../../../rust/m/minimum_window_subsequence.rs) |
| V | [`v/m/minimum_window_subsequence.v`](../../../v/m/minimum_window_subsequence.v) |
| Zig | [`zig/m/minimum_window_subsequence.zig`](../../../zig/m/minimum_window_subsequence.zig) |
