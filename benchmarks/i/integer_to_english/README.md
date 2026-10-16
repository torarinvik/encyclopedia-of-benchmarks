# Integer to English

Convert a signed 32-bit integer to the title-case English words returned by the pinned Java method.

## Contract

- The `i64_array_bytes_output` input is exactly one signed 64-bit value in the Java `int` range.
- Zero returns `Zero`. Positive values are written in groups of three using `Thousand`, `Million`, and `Billion`, without hyphens or “and”.
- The source method's loop skips negative values and returns an empty string; the benchmark preserves that behavior for negative i32 inputs.
- Inputs outside signed 32-bit range or malformed input length return `-1`. Insufficient output capacity returns `-2` without writing output.
- Successful output is ASCII bytes; `workspace.bytes` is 128, enough for the longest signed-i32 positive result.

## Pinned source

The benchmark follows Java [`IntegerToEnglish.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/IntegerToEnglish.java). The source splits positive values into thousand-sized groups and converts each group to words.

[`workload.json`](workload.json) covers zero, the source example, group boundaries, signed-int limits, negative source behavior, malformed inputs, and insufficient capacity.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm integer_to_english --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm integer_to_english
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm integer_to_english
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/integer_to_english.c`](../../../c/i/integer_to_english.c) |
| C3 | [`c3/i/integer_to_english.c3`](../../../c3/i/integer_to_english.c3) |
| C++ | [`cpp/i/integer_to_english.cpp`](../../../cpp/i/integer_to_english.cpp) |
| Elisa | [`elisa/i/integer_to_english.elisa`](../../../elisa/i/integer_to_english.elisa) |
| Nim | [`nim/i/integer_to_english.nim`](../../../nim/i/integer_to_english.nim) |
| Odin | [`odin/i/integer_to_english.odin`](../../../odin/i/integer_to_english.odin) |
| Rust | [`rust/i/integer_to_english.rs`](../../../rust/i/integer_to_english.rs) |
| V | [`v/i/integer_to_english.v`](../../../v/i/integer_to_english.v) |
| Zig | [`zig/i/integer_to_english.zig`](../../../zig/i/integer_to_english.zig) |
