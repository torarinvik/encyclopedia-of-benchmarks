# Remove duplicate characters

This package ports the pinned Dart `removeDups` routine. It keeps the first copy of each character and preserves the order in which distinct characters first appear.

## Contract

- Input is `[text_length, ASCII code values...]`, with 0 to 4,096 bytes and values in `0..127`. The packed array must contain exactly `1 + text_length` values.
- Output is the distinct ASCII bytes in first-occurrence order. The maximum output is 128 bytes.
- Invalid packed input returns `-1` without writing output. Insufficient output capacity, or a null output pointer for nonempty output, returns `-2` without writing output. Empty output succeeds with capacity zero and a null output pointer.
- The Dart source indexes a 256-entry table by UTF-16 code unit, so values above 255 exceed the table. This benchmark uses ASCII `0..127`, a safe subset that keeps the result byte-compatible across languages; it does not model Unicode strings.

## Workload and oracle

[`workload.json`](workload.json) covers empty input, stable first-occurrence order, embedded NUL and control bytes, all ASCII values, maximum input size, buffer capacity, and malformed input. The independent oracle is [`remove_duplicate_characters_oracle.py`](../../remove_duplicate_characters_oracle.py).

Pinned source: [TheAlgorithms/Dart `remove duplicates.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/strings/remove%20duplicates.dart).

## Running and verifying

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm remove_duplicate_characters --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm remove_duplicate_characters
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm remove_duplicate_characters --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/remove_duplicate_characters.c`](../../../c/r/remove_duplicate_characters.c) |
| C3 | [`c3/r/remove_duplicate_characters.c3`](../../../c3/r/remove_duplicate_characters.c3) |
| C++ | [`cpp/r/remove_duplicate_characters.cpp`](../../../cpp/r/remove_duplicate_characters.cpp) |
| Elisa | [`elisa/r/remove_duplicate_characters.elisa`](../../../elisa/r/remove_duplicate_characters.elisa) |
| Nim | [`nim/r/remove_duplicate_characters.nim`](../../../nim/r/remove_duplicate_characters.nim) |
| Odin | [`odin/r/remove_duplicate_characters.odin`](../../../odin/r/remove_duplicate_characters.odin) |
| Rust | [`rust/r/remove_duplicate_characters.rs`](../../../rust/r/remove_duplicate_characters.rs) |
| V | [`v/r/remove_duplicate_characters.v`](../../../v/r/remove_duplicate_characters.v) |
| Zig | [`zig/r/remove_duplicate_characters.zig`](../../../zig/r/remove_duplicate_characters.zig) |
