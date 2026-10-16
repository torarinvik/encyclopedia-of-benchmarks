# Longest palindromic substring (Go Manacher)

This package ports the pinned Go Manacher implementation. Its boundary transform ignores spaces, and the source strips boundary markers from the returned substring.

## Contract

Input is `[count, ASCII codepoints...]`, with count 0..64 and exact packed length. Allowed codepoints are printable ASCII 32..126 except `#`, which is reserved by the source boundary transform. Spaces are ignored. Output is the length of the returned longest palindrome after space removal; tie-sensitive contents are omitted. Empty or all-space input returns 0. Invalid input returns -1.

The workload is in [`workload.json`](workload.json), and the independent oracle is [`longestpalindrome_oracle.py`](../../longestpalindrome_oracle.py). The pinned [Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/manacher/longestpalindrome.go) uses Manacher radius reuse; the ports implement the same transformed-sequence recurrence.

| Language | Port |
|---|---|
| C | [`c/l/longestpalindrome.c`](../../../c/l/longestpalindrome.c) |
| C3 | [`c3/l/longestpalindrome.c3`](../../../c3/l/longestpalindrome.c3) |
| C++ | [`cpp/l/longestpalindrome.cpp`](../../../cpp/l/longestpalindrome.cpp) |
| Elisa | [`elisa/l/longestpalindrome.elisa`](../../../elisa/l/longestpalindrome.elisa) |
| Nim | [`nim/l/longestpalindrome.nim`](../../../nim/l/longestpalindrome.nim) |
| Odin | [`odin/l/longestpalindrome.odin`](../../../odin/l/longestpalindrome.odin) |
| Rust | [`rust/l/longestpalindrome.rs`](../../../rust/l/longestpalindrome.rs) |
| V | [`v/l/longestpalindrome.v`](../../../v/l/longestpalindrome.v) |
| Zig | [`zig/l/longestpalindrome.zig`](../../../zig/l/longestpalindrome.zig) |
