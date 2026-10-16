# Word length sum

## Contract

This benchmark preserves the behavior of Go `Problem17(input string)`: split the input on literal ASCII space and sum each resulting word's Go `len`, which counts bytes. The ABI passes one original byte value in each signed i64 element. Summing the split words is exactly the number of input bytes other than `0x20`; tabs, newlines, NUL, invalid UTF-8 bytes, and every byte in a multibyte UTF-8 character count. Inputs are limited to 4096 bytes with values in `0..=255`; invalid input returns `-1`.

This is separate from Project Euler Problem 17, which computes the letters in number names over a numeric range.

## Workload

[`workload.json`](workload.json) includes empty input, ordinary words, literal and repeated spaces, non-space ASCII whitespace, UTF-8 bytes, embedded NUL, arbitrary byte values, invalid byte values, and the length boundary.

## TheAlgorithms reference

- Go [`Problem17`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_17/problem17.go) splits on spaces and adds `len(word)` for each piece.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/word_length_sum.c](../../../c/w/word_length_sum.c) |
| C3 | [c3/w/word_length_sum.c3](../../../c3/w/word_length_sum.c3) |
| C++ | [cpp/w/word_length_sum.cpp](../../../cpp/w/word_length_sum.cpp) |
| Elisa | [elisa/w/word_length_sum.elisa](../../../elisa/w/word_length_sum.elisa) |
| Nim | [nim/w/word_length_sum.nim](../../../nim/w/word_length_sum.nim) |
| Odin | [odin/w/word_length_sum.odin](../../../odin/w/word_length_sum.odin) |
| Rust | [rust/w/word_length_sum.rs](../../../rust/w/word_length_sum.rs) |
| V | [v/w/word_length_sum.v](../../../v/w/word_length_sum.v) |
| Zig | [zig/w/word_length_sum.zig](../../../zig/w/word_length_sum.zig) |
