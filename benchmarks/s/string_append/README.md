# String append

Append the contents of a second string to the end of the first string.

## Contract

- The `i64_array_bytes_output` ABI accepts `[lengthA, lengthB, bytesA..., bytesB...]` and returns the concatenation of the two strings.
- Each string contains 0 through 64 printable ASCII bytes (32 through 126), excluding embedded NULs as required by the upstream null-terminated string routine.
- Empty strings are allowed; two empty strings produce empty output.
- Malformed packed lengths or nonprintable values return `-1`; insufficient output capacity returns `-2`.
- Results are compared byte for byte; the output does not include a terminating NUL.

## Source semantics

This ports the `append` routine in pinned [TheAlgorithms AArch64 Assembly `append.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/append.s). It scans the destination to its zero terminator, copies the source bytes including the final zero, and thereby forms the concatenated string in place. The pinned [`concatenation.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/concatenation.s) example performs the same operation with two copy loops: one copies the first string, then the next overwrites its terminator with the second string. Its fixed example contains a newline, outside this benchmark's printable-ASCII input domain, but its copy semantics match on the shared domain. The benchmark returns string content without its terminator through the shared byte-output ABI. The assembly examples attribute their source to Rosetta Code under CC BY-SA 4.0; these implementations are portable ports of the operation.

## Workload

[`workload.json`](workload.json) covers nonempty, empty, and invalid packed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/string_append.c`](../../../c/s/string_append.c) |
| C3 | [`c3/s/string_append.c3`](../../../c3/s/string_append.c3) |
| C++ | [`cpp/s/string_append.cpp`](../../../cpp/s/string_append.cpp) |
| Elisa | [`elisa/s/string_append.elisa`](../../../elisa/s/string_append.elisa) |
| Nim | [`nim/s/string_append.nim`](../../../nim/s/string_append.nim) |
| Odin | [`odin/s/string_append.odin`](../../../odin/s/string_append.odin) |
| Rust | [`rust/s/string_append.rs`](../../../rust/s/string_append.rs) |
| V | [`v/s/string_append.v`](../../../v/s/string_append.v) |
| Zig | [`zig/s/string_append.zig`](../../../zig/s/string_append.zig) |

The package uses the `i64_array_bytes_output` benchmark ABI.
