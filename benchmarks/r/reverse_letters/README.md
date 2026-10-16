# Reverse letters

## Review

The pinned Python `reverse_letters` function splits a sentence into whitespace-delimited words and reverses each word whose length is greater than its optional threshold. The default threshold is zero, so every nonempty word is reversed. The pinned F-Sharp `reverseLetters` function splits and rejoins the input, reversing every token. The benchmark fixes Python's threshold at its default and uses nonempty words, making the core transformations equivalent. Python and F-Sharp have different empty and whitespace splitting details; the contract narrows inputs to printable ASCII words separated by one ASCII space, with no leading or trailing separator. ASCII also avoids Python code-point versus .NET UTF-16 reversal differences.

## Contract

The ABI accepts signed 64-bit input `[byte_length, bytes...]` and writes a NUL-terminated ASCII output. `byte_length` is 0 through 256. Bytes are printable ASCII, except ASCII space (32) may appear only between nonempty words, singly. Each word is reversed independently; word order and separators stay in place. The empty string is valid. Invalid inputs return `-1`; insufficient output capacity returns `-2` without writing. The output length equals the input byte length, and the maximum workspace is 257 bytes including the terminator.

## Workload and oracle

[`workload.json`](workload.json) covers empty and single-word inputs, source-style examples, punctuation and digits, exact and insufficient capacity, maximum length, and invalid spacing/byte/length cases. The independent oracle is [`reverse_letters_oracle.py`](../../reverse_letters_oracle.py). The shared byte-output verifier and recorder recognize this algorithm.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_letters.c`](../../../c/r/reverse_letters.c) |
| C3 | [`c3/r/reverse_letters.c3`](../../../c3/r/reverse_letters.c3) |
| C++ | [`cpp/r/reverse_letters.cpp`](../../../cpp/r/reverse_letters.cpp) |
| Elisa | [`elisa/r/reverse_letters.elisa`](../../../elisa/r/reverse_letters.elisa) |
| Nim | [`nim/r/reverse_letters.nim`](../../../nim/r/reverse_letters.nim) |
| Odin | [`odin/r/reverse_letters.odin`](../../../odin/r/reverse_letters.odin) |
| Rust | [`rust/r/reverse_letters.rs`](../../../rust/r/reverse_letters.rs) |
| V | [`v/r/reverse_letters.v`](../../../v/r/reverse_letters.v) |
| Zig | [`zig/r/reverse_letters.zig`](../../../zig/r/reverse_letters.zig) |

## TheAlgorithms references

- [F-Sharp `ReverseLetters.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/ReverseLetters.fs)
- [Python `reverse_letters.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/reverse_letters.py)
