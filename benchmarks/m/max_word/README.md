# Most frequent word

This benchmark ports TheAlgorithms/JavaScript's `maxWord`. It returns the most frequently occurring word in a sentence. With multiple words, counting is case-insensitive and the returned key is lowercase; ties keep the first word encountered. A one-word sentence returns that word unchanged.

## Contract

- The `i64_array_bytes_output` input is `[text_byte_length, ASCII bytes...]`.
- Text is 1 through 512 bytes and consists of ASCII letters separated by exactly one ASCII space. There are no leading or trailing spaces, each word is at most six letters, and uppercase `I` is excluded. These bounds avoid locale-sensitive lowercase behavior, JavaScript object keys that enumerate like integer indices, and inherited `Object.prototype` keys.
- A one-word sentence is returned byte-for-byte. For multiple words, the most frequent case-folded ASCII word is returned in lowercase; ties choose the first key in insertion order.
- Empty text, malformed input, and values outside the bounded domain return `-1`. Insufficient output capacity returns `-2` without writing. Success returns the output byte length. The workspace is 512 bytes.

## Pinned source

- JavaScript [`MaxWord.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/MaxWord.js), commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.
- The independent oracle is [`max_word_oracle.py`](../../max_word_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm max_word --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/m/max_word/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm max_word
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/max_word.c`](../../../c/m/max_word.c) |
| C3 | [`c3/max_word.c3`](../../../c3/m/max_word.c3) |
| C++ | [`cpp/max_word.cpp`](../../../cpp/m/max_word.cpp) |
| Elisa | [`elisa/max_word.elisa`](../../../elisa/m/max_word.elisa) |
| Nim | [`nim/max_word.nim`](../../../nim/m/max_word.nim) |
| Odin | [`odin/max_word.odin`](../../../odin/m/max_word.odin) |
| Rust | [`rust/max_word.rs`](../../../rust/m/max_word.rs) |
| V | [`v/max_word.v`](../../../v/m/max_word.v) |
| Zig | [`zig/max_word.zig`](../../../zig/m/max_word.zig) |
