# Count words

Counts tokens in a string using the pinned Java `wordCount` method: trim Java control characters from both ends, then split on runs of default Java regular-expression whitespace.

## Contract

- Uses the `i64_array_scalar` ABI with an array of ASCII code values representing the string.
- Accepts 0 through 4,096 values, each in 0..127. Inputs outside that domain return `-1`.
- The empty input returns 0. A nonempty input that trims to the empty string returns 1, matching Java's `"".split("\\s+").length` behavior.
- Trimming removes leading and trailing characters with code points at most U+0020, as Java `String.trim()` does.
- Splitting recognizes the default Java `\\s` set: space, tab, line feed, vertical tab, form feed, and carriage return. Other ASCII control characters remain part of a token when internal.

## Source semantics

This benchmark follows pinned [TheAlgorithms Java `CountWords.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/CountWords.java), specifically its `wordCount` method: `s.trim().split("\\s+").length`, with null and empty strings returning 0. Null is not representable by this array ABI; the empty string is represented by an empty array. Java accepts Unicode strings, while this portable workload is restricted to ASCII code values.

The same Java file has a separate `secondaryWordCount` method that removes non-alphanumeric characters before counting. That method is not part of this benchmark. The existing C `word_count` benchmark also has a different contract: it tokenizes on literal spaces and reports a requested token's frequency.

## Workload and build

[`workload.json`](workload.json) covers empty and all-whitespace inputs, tabs/newlines, Java trimming, internal non-whitespace controls, punctuation, and an invalid code value. Build and record with the array-scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm count_words --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/count_words/rust/build.json
```

The nine implementations are in `c/c/count_words.c`, `c3/c/count_words.c3`, `cpp/c/count_words.cpp`, `elisa/c/count_words.elisa`, `nim/c/count_words.nim`, `odin/c/count_words.odin`, `rust/c/count_words.rs`, `v/c/count_words.v`, and `zig/c/count_words.zig`.
