# Remove duplicate words

This package ports the pinned F# `removeDuplicates` routine. It splits on whitespace, keeps distinct substrings in first-seen order, then joins them with one ASCII space. Word equality is exact and case-sensitive.

## Contract

- Input is `[text_length, ASCII code values...]`, with 0 to 4,096 bytes and values in `0..127`. The packed array must contain exactly `1 + text_length` values.
- Within ASCII, the source's whitespace separators are TAB through CARRIAGE RETURN (`0x09..0x0D`) and SPACE (`0x20`). Other ASCII bytes, including NUL, remain part of a word.
- The source calls parameterless `.NET String.Split()`, whose default `StringSplitOptions.None` retains empty substrings. `Array.distinct` keeps the first empty substring once, so a leading, trailing, or repeated separator can contribute an empty word to the output. For example, `"a  b"` remains `"a  b"`; a normal single separator between words is rejoined as one space. The byte domain intentionally excludes Unicode whitespace and other Unicode text. [Microsoft documents the default empty-substring behavior](https://learn.microsoft.com/en-us/dotnet/api/system.stringsplitoptions).
- Invalid packed input returns `-1` without writing output. Insufficient output capacity, or a null output pointer for nonempty output, returns `-2` without writing output. Empty output succeeds with capacity zero and a null output pointer.

## Workload and oracle

[`workload.json`](workload.json) covers stable deduplication, case sensitivity, ASCII whitespace variants, retained empty substrings, binary word bytes, maximum input/output length, and output-capacity errors. The independent oracle is [`remove_duplicate_words_oracle.py`](../../remove_duplicate_words_oracle.py).

Pinned source: [TheAlgorithms/F-Sharp `RemoveDuplicates.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/RemoveDuplicates.fs).

## Running and verifying

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm remove_duplicate_words --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm remove_duplicate_words
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm remove_duplicate_words --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/remove_duplicate_words.c`](../../../c/r/remove_duplicate_words.c) |
| C3 | [`c3/r/remove_duplicate_words.c3`](../../../c3/r/remove_duplicate_words.c3) |
| C++ | [`cpp/r/remove_duplicate_words.cpp`](../../../cpp/r/remove_duplicate_words.cpp) |
| Elisa | [`elisa/r/remove_duplicate_words.elisa`](../../../elisa/r/remove_duplicate_words.elisa) |
| Nim | [`nim/r/remove_duplicate_words.nim`](../../../nim/r/remove_duplicate_words.nim) |
| Odin | [`odin/r/remove_duplicate_words.odin`](../../../odin/r/remove_duplicate_words.odin) |
| Rust | [`rust/r/remove_duplicate_words.rs`](../../../rust/r/remove_duplicate_words.rs) |
| V | [`v/r/remove_duplicate_words.v`](../../../v/r/remove_duplicate_words.v) |
| Zig | [`zig/r/remove_duplicate_words.zig`](../../../zig/r/remove_duplicate_words.zig) |
