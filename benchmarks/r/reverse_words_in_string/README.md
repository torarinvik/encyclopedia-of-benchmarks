# Reverse words in a string

Reverse the order of words after applying the pinned Java method’s `trim()`, `split("\\s+")`, and single-space join. This package preserves the Java method’s ASCII behavior on a bounded byte domain.

## Contract

- Input is a packed signed-i64 array `[text_length, ASCII byte values...]`, with `text_length` from 0 through 256 and the total array length exactly `text_length + 1`.
- Java `trim()` behavior is preserved: leading and trailing bytes from 0 through 0x20 are removed.
- Java’s default ASCII `\\s+` behavior is preserved for spaces, tabs, line feeds, vertical tabs, form feeds, and carriage returns. Each run separates words; the output joins reversed words with one ASCII space.
- Other bytes, including embedded NUL and ASCII controls outside `\\s`, remain part of their word. Output is raw ASCII bytes with no trailing NUL.
- Malformed headers, lengths, values, or a null input pointer return `-1`. Insufficient output capacity or a null output pointer for nonempty output returns `-2`. Empty output succeeds with length zero.

This differs from the existing [`reverse_words`](../reverse_words/README.md) bounded contract, which accepts only single ASCII spaces between words. The Java source also supports Unicode; this benchmark limits it to ASCII for portable byte-level behavior.

## Workload and oracle

[`workload.json`](workload.json) covers whitespace runs and controls, edge trimming, punctuation, embedded NUL, maximum length, malformed input, and output capacity. The independent oracle is [`reverse_words_in_string_oracle.py`](../../reverse_words_in_string_oracle.py).

Pinned source: [TheAlgorithms/Java `ReverseWordsInString.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/ReverseWordsInString.java).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_words_in_string --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_words_in_string
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm reverse_words_in_string
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_words_in_string.c`](../../../c/r/reverse_words_in_string.c) |
| C3 | [`c3/r/reverse_words_in_string.c3`](../../../c3/r/reverse_words_in_string.c3) |
| C++ | [`cpp/r/reverse_words_in_string.cpp`](../../../cpp/r/reverse_words_in_string.cpp) |
| Elisa | [`elisa/r/reverse_words_in_string.elisa`](../../../elisa/r/reverse_words_in_string.elisa) |
| Nim | [`nim/r/reverse_words_in_string.nim`](../../../nim/r/reverse_words_in_string.nim) |
| Odin | [`odin/r/reverse_words_in_string.odin`](../../../odin/r/reverse_words_in_string.odin) |
| Rust | [`rust/r/reverse_words_in_string.rs`](../../../rust/r/reverse_words_in_string.rs) |
| V | [`v/r/reverse_words_in_string.v`](../../../v/r/reverse_words_in_string.v) |
| Zig | [`zig/r/reverse_words_in_string.zig`](../../../zig/r/reverse_words_in_string.zig) |
