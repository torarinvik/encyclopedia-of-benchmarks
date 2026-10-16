# Length of Last Word

`length_of_last_word` returns the byte length of the final word in a bounded packed byte string, matching the pinned Java method on the documented byte domain.

## Contract

The `i64_array_scalar` input is `[byte_length, byte_0, ..., byte_(n-1)]`. The length must be 0 through 128, each byte must be 0 through 255, and the packed array must contain exactly `byte_length + 1` values. Byte `32` (ASCII space) separates words. Trailing spaces are ignored; every other byte, including tabs, NUL, and high bytes, is part of a word. If the string contains no non-space byte, the result is 0. Malformed lengths or bytes return -1.

The pinned Java implementation scans UTF-16 code units and treats only the literal space character as a separator. This benchmark bounds input to byte values 0 through 255, so each packed byte corresponds to one Java `char` value and preserves that behavior. It does not model Java strings containing code units above 255 or surrogate pairs.

## Source

The implementation is from [`LengthOfLastWord.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LengthOfLastWord.java), pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. It skips trailing spaces, then counts consecutive non-space characters. The upstream source repository is licensed under [MIT](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).

[`workload.json`](workload.json) includes empty and spaces-only strings, trailing and leading spaces, tabs and binary byte values, malformed packed inputs, and the 128-byte limit. The independent oracle is [`length_of_last_word_oracle.py`](../../length_of_last_word_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm length_of_last_word --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/length_of_last_word/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms length_of_last_word
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/length_of_last_word.c`](../../../c/l/length_of_last_word.c) |
| C3 | [`c3/l/length_of_last_word.c3`](../../../c3/l/length_of_last_word.c3) |
| C++ | [`cpp/l/length_of_last_word.cpp`](../../../cpp/l/length_of_last_word.cpp) |
| Elisa | [`elisa/l/length_of_last_word.elisa`](../../../elisa/l/length_of_last_word.elisa) |
| Nim | [`nim/l/length_of_last_word.nim`](../../../nim/l/length_of_last_word.nim) |
| Odin | [`odin/l/length_of_last_word.odin`](../../../odin/l/length_of_last_word.odin) |
| Rust | [`rust/l/length_of_last_word.rs`](../../../rust/l/length_of_last_word.rs) |
| V | [`v/l/length_of_last_word.v`](../../../v/l/length_of_last_word.v) |
| Zig | [`zig/l/length_of_last_word.zig`](../../../zig/l/length_of_last_word.zig) |
