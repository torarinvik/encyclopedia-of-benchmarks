# Palindromic partitioning

The pinned Java `minimalPartitions` builds a table identifying palindromic substrings, then uses a prefix dynamic program to return the minimum number of cuts that partition the entire string into palindromes.

## Contract

Input is `[byte_count, ASCII bytes...]`, with 1 to 64 bytes. Any ASCII byte is accepted, including spaces and punctuation. The scalar result is the minimum cut count. Empty input is invalid because the pinned implementation indexes the final entry of an empty array.

See [`workload.json`](workload.json) and the runtime [oracle](../../palindromic_partitioning_oracle.py). Pinned source: [TheAlgorithms/Java `PalindromicPartitioning.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/PalindromicPartitioning.java).

| Language | Port |
|---|---|
| C | [`c/p/palindromic_partitioning.c`](../../../c/p/palindromic_partitioning.c) |
| C3 | [`c3/p/palindromic_partitioning.c3`](../../../c3/p/palindromic_partitioning.c3) |
| C++ | [`cpp/p/palindromic_partitioning.cpp`](../../../cpp/p/palindromic_partitioning.cpp) |
| Elisa | [`elisa/p/palindromic_partitioning.elisa`](../../../elisa/p/palindromic_partitioning.elisa) |
| Nim | [`nim/p/palindromic_partitioning.nim`](../../../nim/p/palindromic_partitioning.nim) |
| Odin | [`odin/p/palindromic_partitioning.odin`](../../../odin/p/palindromic_partitioning.odin) |
| Rust | [`rust/p/palindromic_partitioning.rs`](../../../rust/p/palindromic_partitioning.rs) |
| V | [`v/p/palindromic_partitioning.v`](../../../v/p/palindromic_partitioning.v) |
| Zig | [`zig/p/palindromic_partitioning.zig`](../../../zig/p/palindromic_partitioning.zig) |
