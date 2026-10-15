# Reverse Only Letters

This benchmark ports TheAlgorithms/C's LeetCode 917 two-pointer algorithm. It reverses ASCII English letters while keeping punctuation, spaces, digits, and other printable ASCII characters at their original positions.

## Contract

- Input is a printable ASCII byte array of length 0 to 4,096. Values must be in 32..126.
- Only `A` through `Z` and `a` through `z` are letters. Other values stay in place.
- Invalid lengths or values return `-1`.
- The transformed bytes are written to a separate output buffer. The return value is the byte length.
- Insufficient output capacity returns `-2` before writing output.

The benchmark fixes letter classification to ASCII so every language has the same behavior regardless of locale. It adapts the source's in-place C-string mutation to the byte-array ABI.

Run `python3 benchmarks/verify_reverse_only_letters.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short patterns, seeded longer inputs, invalid values, the maximum length, output-capacity failure, and workload records.

## Implementations

Portable ports are [`c/r/reverse_only_letters.c`](../../../c/r/reverse_only_letters.c), [`c3/r/reverse_only_letters.c3`](../../../c3/r/reverse_only_letters.c3), [`cpp/r/reverse_only_letters.cpp`](../../../cpp/r/reverse_only_letters.cpp), [`elisa/r/reverse_only_letters.elisa`](../../../elisa/r/reverse_only_letters.elisa), [`nim/r/reverse_only_letters.nim`](../../../nim/r/reverse_only_letters.nim), [`odin/r/reverse_only_letters.odin`](../../../odin/r/reverse_only_letters.odin), [`rust/r/reverse_only_letters.rs`](../../../rust/r/reverse_only_letters.rs), [`v/r/reverse_only_letters.v`](../../../v/r/reverse_only_letters.v), and [`zig/r/reverse_only_letters.zig`](../../../zig/r/reverse_only_letters.zig). They use generic compiler targets and no architecture-specific instructions.

## Upstream reference

- [TheAlgorithms/C LeetCode 917](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/917.c)
