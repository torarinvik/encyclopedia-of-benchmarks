# Remove vowels

This benchmark models the final `remove_vowels` definition in the pinned Ruby source. It lowercases ASCII uppercase letters, removes ASCII `a`, `e`, `i`, `o`, and `u`, and preserves the order of all remaining bytes.

## Contract

- Input is `[text_length, ASCII byte values...]`, with 0 to 4,096 bytes and values in `0..127`. The packed array must contain exactly `1 + text_length` values.
- Output is the lowercased ASCII text with the five lowercase vowels removed. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing. Output length is the return value.
- The benchmark restricts input to ASCII. Ruby's Unicode case conversion is outside this byte-oriented contract.

[`workload.json`](workload.json) covers empty input, the upstream example, uppercase vowels, mixed case and control bytes, all vowels, maximum length, malformed inputs, and insufficient capacity. The independent oracle is [`remove_vowels_oracle.py`](../../remove_vowels_oracle.py).

Build and record with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm remove_vowels --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm remove_vowels
```

## Implementations

The nine portable ports are in `c/r/remove_vowels.c`, `c3/r/remove_vowels.c3`, `cpp/r/remove_vowels.cpp`, `elisa/r/remove_vowels.elisa`, `nim/r/remove_vowels.nim`, `odin/r/remove_vowels.odin`, `rust/r/remove_vowels.rs`, `v/r/remove_vowels.v`, and `zig/r/remove_vowels.zig`.

## Pinned source

- [TheAlgorithms/Ruby `remove_vowels.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/strings/remove_vowels.rb). The file defines `remove_vowels` three times; Ruby uses the final definition, which calls `downcase.delete('aeiou')`.
