# Remove duplicate characters from a string

This benchmark ports TheAlgorithms/Java's `RemoveDuplicateFromString.removeDuplicate`. It keeps the first occurrence of each Java character and preserves the order of those first occurrences.

## Contract

- The `i64_array_bytes_output` input is `[text_byte_length, ASCII byte values...]`.
- The byte length is 0 through 512. Each byte is 0 through 127, including NUL and other ASCII control characters. In this bounded domain, each byte corresponds to one Java UTF-16 code unit.
- The output is the unique input bytes in first-occurrence order. All 128 ASCII values are valid data, including NUL; output length distinguishes data from an empty result.
- Malformed inputs return `-1`. Insufficient output capacity returns `-2` without writing. Success returns the output byte length. The workspace is 512 bytes.

The domain preserves the source's character equality and order while avoiding Java surrogate pairs, which cannot be represented as individual bytes.

## Pinned source

- Java [`RemoveDuplicateFromString.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/RemoveDuplicateFromString.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- Source algorithm: scan left to right and append a character only when it is not already in the accumulated output.
- The independent oracle is [`remove_duplicate_from_string_oracle.py`](../../remove_duplicate_from_string_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm remove_duplicate_from_string --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/r/remove_duplicate_from_string/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm remove_duplicate_from_string
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/remove_duplicate_from_string.c`](../../../c/r/remove_duplicate_from_string.c) |
| C3 | [`c3/remove_duplicate_from_string.c3`](../../../c3/r/remove_duplicate_from_string.c3) |
| C++ | [`cpp/remove_duplicate_from_string.cpp`](../../../cpp/r/remove_duplicate_from_string.cpp) |
| Elisa | [`elisa/remove_duplicate_from_string.elisa`](../../../elisa/r/remove_duplicate_from_string.elisa) |
| Nim | [`nim/remove_duplicate_from_string.nim`](../../../nim/r/remove_duplicate_from_string.nim) |
| Odin | [`odin/remove_duplicate_from_string.odin`](../../../odin/r/remove_duplicate_from_string.odin) |
| Rust | [`rust/remove_duplicate_from_string.rs`](../../../rust/r/remove_duplicate_from_string.rs) |
| V | [`v/remove_duplicate_from_string.v`](../../../v/r/remove_duplicate_from_string.v) |
| Zig | [`zig/remove_duplicate_from_string.zig`](../../../zig/r/remove_duplicate_from_string.zig) |
