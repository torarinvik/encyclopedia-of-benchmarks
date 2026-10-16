# Keyword shifted alphabet cipher

This benchmark ports TheAlgorithms/JavaScript's `encrypt` and `decrypt` functions from `KeywordShiftedAlphabet.js`. The keyword defines a substitution alphabet by placing its letters first, followed by the unused lowercase letters in alphabetical order.

## Contract

- The `i64_array_bytes_output` input is `[operation, keyword_length, message_length, keyword bytes..., message bytes...]`. Operation `0` encrypts and operation `1` decrypts.
- The keyword is 1 through 26 ASCII letters with no duplicate letters after ASCII lowercasing. The message is 1 through 512 ASCII bytes (0 through 127), so NUL and nonletter bytes are preserved.
- Letter substitution is case-insensitive and preserves the message letter's ASCII case. All nonletters pass through unchanged. Empty keyword/message, duplicate keywords, malformed lengths, or values outside the bounded domain return `-1`.
- Insufficient output capacity returns `-2` without writing. Success returns the message byte length. The workspace is 512 bytes.

The pinned code documents unique keyword letters, although its JavaScript `forEach` callback does not propagate its duplicate-check return value. The bounded contract enforces the documented keyword precondition.

## Pinned source

- JavaScript [`KeywordShiftedAlphabet.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/KeywordShiftedAlphabet.js), commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.
- The independent oracle is [`keyword_shifted_alphabet_oracle.py`](../../keyword_shifted_alphabet_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm keyword_shifted_alphabet --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/k/keyword_shifted_alphabet/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm keyword_shifted_alphabet
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/keyword_shifted_alphabet.c`](../../../c/k/keyword_shifted_alphabet.c) |
| C3 | [`c3/keyword_shifted_alphabet.c3`](../../../c3/k/keyword_shifted_alphabet.c3) |
| C++ | [`cpp/keyword_shifted_alphabet.cpp`](../../../cpp/k/keyword_shifted_alphabet.cpp) |
| Elisa | [`elisa/keyword_shifted_alphabet.elisa`](../../../elisa/k/keyword_shifted_alphabet.elisa) |
| Nim | [`nim/keyword_shifted_alphabet.nim`](../../../nim/k/keyword_shifted_alphabet.nim) |
| Odin | [`odin/keyword_shifted_alphabet.odin`](../../../odin/k/keyword_shifted_alphabet.odin) |
| Rust | [`rust/keyword_shifted_alphabet.rs`](../../../rust/k/keyword_shifted_alphabet.rs) |
| V | [`v/keyword_shifted_alphabet.v`](../../../v/k/keyword_shifted_alphabet.v) |
| Zig | [`zig/keyword_shifted_alphabet.zig`](../../../zig/k/keyword_shifted_alphabet.zig) |
