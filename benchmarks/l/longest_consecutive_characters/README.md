# Longest Consecutive Characters

The pinned C# method scans a nonempty string once and returns the character and length of its longest run of equal adjacent characters. It updates the winner only when a run is strictly longer, so an earlier run wins ties.

## Contract

Input is `[length, ASCII_codes...]`, with 1 to 256 character codes in `[0, 127]`. Invalid input returns `-1`.

Output is three bytes: the winning character code, followed by the run length as a little-endian unsigned 16-bit value. The function returns 3. Insufficient output capacity returns `-2`.

The numeric character representation makes the ports independent of each language's string encoding. See [`workload.json`](workload.json) for tie, NUL, malformed-input, and capacity cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/longest_consecutive_characters.c`](../../../c/l/longest_consecutive_characters.c) |
| C3 | [`c3/l/longest_consecutive_characters.c3`](../../../c3/l/longest_consecutive_characters.c3) |
| C++ | [`cpp/l/longest_consecutive_characters.cpp`](../../../cpp/l/longest_consecutive_characters.cpp) |
| Elisa | [`elisa/l/longest_consecutive_characters.elisa`](../../../elisa/l/longest_consecutive_characters.elisa) |
| Nim | [`nim/l/longest_consecutive_characters.nim`](../../../nim/l/longest_consecutive_characters.nim) |
| Odin | [`odin/l/longest_consecutive_characters.odin`](../../../odin/l/longest_consecutive_characters.odin) |
| Rust | [`rust/l/longest_consecutive_characters.rs`](../../../rust/l/longest_consecutive_characters.rs) |
| V | [`v/l/longest_consecutive_characters.v`](../../../v/l/longest_consecutive_characters.v) |
| Zig | [`zig/l/longest_consecutive_characters.zig`](../../../zig/l/longest_consecutive_characters.zig) |

## Pinned source

[TheAlgorithms/C-Sharp `GeneralStringAlgorithms.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Strings/GeneralStringAlgorithms.cs)
