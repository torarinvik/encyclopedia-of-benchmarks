# Entropy of information

The pinned Python source analyzes a string into single-character counts and bigram counts, then prints three rounded entropy values. This package captures those three text lines in the byte-output ABI.

## Contract

- Uses the `i64_array_bytes_output` ABI. Input is `[text_length, ASCII_codepoint_0, ...]`.
- `text_length` must be 1 through 512, the array length must equal `text_length + 1`, and each codepoint must be 0 through 127.
- The source counts every input character in the single-character denominator. Its bigram counts include one leading pair consisting of a space and the first character, followed by every adjacent input pair, so that denominator is also the text length.
- In both entropy sums, only space and lowercase `a` through `z` contribute to the numerator. Other ASCII characters still count in the denominator, matching the source's fixed alphabet loop.
- Output is three newline-terminated values formatted with one decimal place: single-character entropy, bigram entropy, and bigram entropy minus single-character entropy. Each value is first rounded to an integer with Python's ties-to-even `round` behavior, then formatted with one decimal place. The byte output is 12 or 13 bytes because a negative final difference needs a sign byte.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing a partial result.

[`workload.json`](workload.json) covers the source example, uniform and mixed text, case and punctuation filtering, an exact ties-to-even rounding case, maximum input length, invalid inputs, and insufficient capacities below both valid payload lengths.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm entropy --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/entropy/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm entropy --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/e/entropy.c`](../../../c/e/entropy.c) |
| C3 | [`c3/e/entropy.c3`](../../../c3/e/entropy.c3) |
| C++ | [`cpp/e/entropy.cpp`](../../../cpp/e/entropy.cpp) |
| Elisa | [`elisa/e/entropy.elisa`](../../../elisa/e/entropy.elisa) |
| Nim | [`nim/e/entropy.nim`](../../../nim/e/entropy.nim) |
| Odin | [`odin/e/entropy.odin`](../../../odin/e/entropy.odin) |
| Rust | [`rust/e/entropy.rs`](../../../rust/e/entropy.rs) |
| V | [`v/e/entropy.v`](../../../v/e/entropy.v) |
| Zig | [`zig/e/entropy.zig`](../../../zig/e/entropy.zig) |

## TheAlgorithms reference

- [Python `entropy.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/entropy.py)
