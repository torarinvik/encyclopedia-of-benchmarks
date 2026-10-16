# Unique Letters Count

Count ASCII letters case-insensitively, ignore nonletters, and report each letter's frequency in first-appearance order. This captures the data transformation performed by the pinned R console example while giving it a bounded cross-platform input and output contract.

## Contract

- Pack the `i64_array_bytes_output` input as `[text_length, byte...]`. The text length is from 0 through 256, and the packed input length must equal `text_length+1`.
- Input bytes must be ASCII values from 0 through 127. ASCII uppercase and lowercase letters are counted as the same lowercase letter; all other ASCII bytes are ignored.
- For each distinct letter, emit its lowercase ASCII code and frequency as two little-endian signed 32-bit integers. Preserve the order in which letters first appear. Return the number of unique letters; if no letters occur, return 0 and zero bytes.
- Malformed input returns `-1`. Output capacity must hold `8*min(text_length,26)` bytes; insufficient capacity returns `-2` without writing. Maximum workspace is 208 bytes.

## Source and workload

The pinned R example removes non-ASCII letters, lowercases the remaining text, and prints each unique letter with its frequency. Indexing the frequency table by the unique-letter sequence preserves first-appearance order. The portable contract makes its character domain explicit as ASCII and replaces console I/O with a length-prefixed byte array.

- [TheAlgorithms/R `unique.letters.count.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/unique.letters.count.r)
- [MIT license](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/LICENSE)

[`workload.json`](workload.json) covers empty and punctuation-only text, mixed case, first-seen ordering, all 26 letters, maximum input length, invalid bytes and packing, and insufficient capacity. [`unique_letters_count_oracle.py`](../../unique_letters_count_oracle.py) independently filters the ASCII input and derives counts with a frequency table.

Build with the shared byte-output ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm unique_letters_count --language rust
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm unique_letters_count
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/unique_letters_count.c`](../../../c/u/unique_letters_count.c) |
| C3 | [`c3/u/unique_letters_count.c3`](../../../c3/u/unique_letters_count.c3) |
| C++ | [`cpp/u/unique_letters_count.cpp`](../../../cpp/u/unique_letters_count.cpp) |
| Elisa | [`elisa/u/unique_letters_count.elisa`](../../../elisa/u/unique_letters_count.elisa) |
| Nim | [`nim/u/unique_letters_count.nim`](../../../nim/u/unique_letters_count.nim) |
| Odin | [`odin/u/unique_letters_count.odin`](../../../odin/u/unique_letters_count.odin) |
| Rust | [`rust/u/unique_letters_count.rs`](../../../rust/u/unique_letters_count.rs) |
| V | [`v/u/unique_letters_count.v`](../../../v/u/unique_letters_count.v) |
| Zig | [`zig/u/unique_letters_count.zig`](../../../zig/u/unique_letters_count.zig) |
