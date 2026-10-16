# Words to number

This benchmark ports the pinned Java `WordsToNumber.convert` parser. It preserves the source's word ordering checks, punctuation splitting, `and`/`negative` errors, and `BigDecimal.toString()` scale for the bounded input grammar below. It remains distinct from [`number_to_words`](../../n/number_to_words/README.md), which performs the opposite conversion.

## Contract

- Input is `[byte_length, bytes...]`, with 0 through 128 printable ASCII bytes (`0x20` through `0x7e`). Input is case-insensitive. ASCII space, comma, and hyphen each separate tokens; repeated and edge separators are ignored as in the Java preprocessor. Other bytes outside the declared domain return `-1`.
- Number tokens are `zero` through `nineteen`, plus `twenty`, `thirty`, `forty`, `fifty`, `sixty`, `seventy`, `eighty`, and `ninety`. The parser also supports `hundred`, descending `thousand`/`million`/`billion`/`trillion` scales, an optional leading `negative`, the source's conditional `and`, and `point` followed by one to three number words. The fractional-word bound keeps all results in plain decimal form while retaining the source's decimal scale.
- The `point` digits are the decimal spellings of the following number values, concatenated. Thus the source's `point twenty` quirk produces `0.20`, not `0.2`. Trailing zeros from `BigDecimal.toString()` are preserved.
- Success writes the ASCII decimal string and returns its byte length. A null output pointer or short buffer returns `-2`. Source exception categories are distinct: `-3` empty/separator-only (`NULL_INPUT`), `-4` unknown word, `-5` unexpected word, `-6` unexpected word after point, `-7` missing decimal digits, `-8` repeated negative, `-9` misplaced negative, and `-10` invalid conjunction. Malformed packed input returns `-1`.
- The source's `isAdditionSafe` rule is preserved: it compares the decimal-string lengths of the current chunk and the next number instead of applying a conventional linguistic grammar.

[`workload.json`](workload.json) covers source examples and quirks, case folding, separators, scales, negative and decimal forms, each error category, malformed input, and capacity. The independent oracle is [`words_to_number_oracle.py`](../../words_to_number_oracle.py).

## Pinned source

[Java `WordsToNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/WordsToNumber.java) preprocesses words, accumulates scale chunks using `BigDecimal`, and appends decimal word values after `point`. Its error enum and exception class are included in the pinned source file.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm words_to_number --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm words_to_number
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/w/words_to_number.c`](../../../c/w/words_to_number.c) |
| C3 | [`c3/w/words_to_number.c3`](../../../c3/w/words_to_number.c3) |
| C++ | [`cpp/w/words_to_number.cpp`](../../../cpp/w/words_to_number.cpp) |
| Elisa | [`elisa/w/words_to_number.elisa`](../../../elisa/w/words_to_number.elisa) |
| Nim | [`nim/w/words_to_number.nim`](../../../nim/w/words_to_number.nim) |
| Odin | [`odin/w/words_to_number.odin`](../../../odin/w/words_to_number.odin) |
| Rust | [`rust/w/words_to_number.rs`](../../../rust/w/words_to_number.rs) |
| V | [`v/w/words_to_number.v`](../../../v/w/words_to_number.v) |
| Zig | [`zig/w/words_to_number.zig`](../../../zig/w/words_to_number.zig) |
