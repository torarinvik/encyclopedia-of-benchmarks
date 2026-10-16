# Longest increasing subsequence, iterative

The pinned Python source uses an O(n²) dynamic program and accepts a previous value when it is less than or equal to the current value. This is therefore a longest non-decreasing subsequence.

## Contract

Input is `[count, values...]`, where count is 0..64, the packed length is exactly count+1, and each value is within ±1,000,000. Output is the length of the source-produced subsequence; this omits tie-sensitive sequence contents while preserving the DP result. Empty input returns 0. Invalid input returns -1.

See the [workload](workload.json), [independent oracle](../../longest_increasing_subsequence_iterative_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/longest_increasing_subsequence_iterative.py).

| Language | Port |
|---|---|
| C | [`c/l/longest_increasing_subsequence_iterative.c`](../../../c/l/longest_increasing_subsequence_iterative.c) |
| C3 | [`c3/l/longest_increasing_subsequence_iterative.c3`](../../../c3/l/longest_increasing_subsequence_iterative.c3) |
| C++ | [`cpp/l/longest_increasing_subsequence_iterative.cpp`](../../../cpp/l/longest_increasing_subsequence_iterative.cpp) |
| Elisa | [`elisa/l/longest_increasing_subsequence_iterative.elisa`](../../../elisa/l/longest_increasing_subsequence_iterative.elisa) |
| Nim | [`nim/l/longest_increasing_subsequence_iterative.nim`](../../../nim/l/longest_increasing_subsequence_iterative.nim) |
| Odin | [`odin/l/longest_increasing_subsequence_iterative.odin`](../../../odin/l/longest_increasing_subsequence_iterative.odin) |
| Rust | [`rust/l/longest_increasing_subsequence_iterative.rs`](../../../rust/l/longest_increasing_subsequence_iterative.rs) |
| V | [`v/l/longest_increasing_subsequence_iterative.v`](../../../v/l/longest_increasing_subsequence_iterative.v) |
| Zig | [`zig/l/longest_increasing_subsequence_iterative.zig`](../../../zig/l/longest_increasing_subsequence_iterative.zig) |
