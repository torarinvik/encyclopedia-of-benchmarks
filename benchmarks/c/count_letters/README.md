# Count letter occurrences

Count occurrences of a requested ASCII letter in a bounded string, ignoring letter case. This measures one selected entry from the frequency map produced by the pinned JavaScript source.

## Contract

The `i64_array_scalar` input is `[query_letter, text_length, ASCII letters...]`. The query is one ASCII letter, the text length is 0 through 256, and the packed array must contain exactly `text_length + 2` values. Uppercase and lowercase query/text letters are equivalent. Return the count from 0 through 256; malformed packing or a nonletter code returns `-1`.

The source returns a map containing every letter frequency. The shared scalar contract selects the count for one requested letter. The benchmark restricts the source's text to ASCII letters; digits, punctuation, underscores, spaces, and non-ASCII characters are outside the bounded domain.

## Source

The pinned JavaScript [`CountLetters.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CountLetters.js) lowercases its input and counts each character. It rejects nonword characters and digits; this benchmark uses a stricter ASCII-letter subset and exposes one selected frequency.

## Workload and recording

[`workload.json`](workload.json) covers repeated and mixed-case letters, absent letters, empty and maximum-length text, and malformed inputs.

The shared `i64_array_scalar` runner validates each expected result against a bounded case-insensitive ASCII frequency oracle.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm count_letters --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/count_letters/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/c/count_letters.c`](../../../c/c/count_letters.c) |
| C3 | [`c3/c/count_letters.c3`](../../../c3/c/count_letters.c3) |
| C++ | [`cpp/c/count_letters.cpp`](../../../cpp/c/count_letters.cpp) |
| Elisa | [`elisa/c/count_letters.elisa`](../../../elisa/c/count_letters.elisa) |
| Nim | [`nim/c/count_letters.nim`](../../../nim/c/count_letters.nim) |
| Odin | [`odin/c/count_letters.odin`](../../../odin/c/count_letters.odin) |
| Rust | [`rust/c/count_letters.rs`](../../../rust/c/count_letters.rs) |
| V | [`v/c/count_letters.v`](../../../v/c/count_letters.v) |
| Zig | [`zig/c/count_letters.zig`](../../../zig/c/count_letters.zig) |
