# Largest and smallest words

This benchmark ports TheAlgorithms/Python's `find_smallest_and_largest_words`. It splits a bounded ASCII sentence, strips the source's edge punctuation set from each token, then returns the first shortest and first longest words.

## Contract

- The `i64_array_bytes_output` input is `[text_byte_length, printable ASCII bytes...]`. Text is 1 through 512 bytes. ASCII space separates words and leading, trailing, or repeated spaces collapse as Python `str.split()` does. All-space text is outside the valid domain because the source returns `(None, None)` when it finds no words.
- The source strips any leading/trailing characters from `.,!?()[]{}` on each word. Punctuation-only words therefore become empty strings and remain candidates. Ties for both shortest and longest words select the first candidate.
- The output is two consecutive records: little-endian `u32` byte length, smallest word bytes, little-endian `u32` byte length, largest word bytes. Empty stripped words are represented by a zero length. Malformed input returns `-1`; insufficient output capacity returns `-2` without writing; success returns encoded byte length.
- The workspace is 1,032 bytes, enough for two 512-byte words and two length headers.

The printable ASCII bound keeps Python character lengths aligned with byte lengths and restricts whitespace splitting to the documented ASCII space behavior.

## Pinned source

- Python [`largest_smallest_words.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/largest_smallest_words.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`.
- The independent oracle is [`largest_smallest_words_oracle.py`](../../largest_smallest_words_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm largest_smallest_words --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/largest_smallest_words/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm largest_smallest_words
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/largest_smallest_words.c`](../../../c/l/largest_smallest_words.c) |
| C3 | [`c3/largest_smallest_words.c3`](../../../c3/l/largest_smallest_words.c3) |
| C++ | [`cpp/largest_smallest_words.cpp`](../../../cpp/l/largest_smallest_words.cpp) |
| Elisa | [`elisa/largest_smallest_words.elisa`](../../../elisa/l/largest_smallest_words.elisa) |
| Nim | [`nim/largest_smallest_words.nim`](../../../nim/l/largest_smallest_words.nim) |
| Odin | [`odin/largest_smallest_words.odin`](../../../odin/l/largest_smallest_words.odin) |
| Rust | [`rust/largest_smallest_words.rs`](../../../rust/l/largest_smallest_words.rs) |
| V | [`v/largest_smallest_words.v`](../../../v/l/largest_smallest_words.v) |
| Zig | [`zig/largest_smallest_words.zig`](../../../zig/l/largest_smallest_words.zig) |
