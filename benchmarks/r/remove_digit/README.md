# Remove digit

Remove one decimal digit from the magnitude of an integer and return the largest resulting integer. This follows the pinned Python implementation, including its treatment of negative inputs.

## Contract

- Input is one signed 64-bit integer `num`. Valid inputs satisfy `INT64_MIN < num <= INT64_MAX` and `abs(num) >= 10`.
- Convert the magnitude to decimal digits. For each digit position, remove that digit, parse the remaining digits as a base-10 integer, and return the maximum candidate.
- The sign is discarded before digit removal, so `-11` returns `1`. If a removal leaves leading zeroes such as `"000"`, parsing yields zero and that candidate participates in the maximum.
- The Python source raises `ValueError` for zero and one-digit inputs because removing the only digit creates an empty string. The benchmark maps those cases and the excluded `INT64_MIN` endpoint to `-1`, the scalar ABI invalid-input sentinel.
- The output is always nonnegative and fits signed 64-bit range. The algorithm takes `O(d²)` time for `d` decimal digits; the ports use `O(1)` auxiliary space.

## Source and related algorithms

The pinned [Python `remove_digit.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/remove_digit.py) creates each string produced by deleting one position from `str(abs(num))`, converts the candidates to integers, and returns their maximum. This is a decimal digit-deletion operation; it does not reverse the number or search for a prime.

## Workload and build

[`workload.json`](workload.json) covers positive and negative inputs, repeated digits, zeroes left after deletion, one digit removed from a two-digit input, signed-i64 bounds, and invalid source cases. All nine ports use the shared scalar ABI.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm remove_digit --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/r/remove_digit/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/remove_digit.c`](../../../c/r/remove_digit.c) |
| C3 | [`c3/r/remove_digit.c3`](../../../c3/r/remove_digit.c3) |
| C++ | [`cpp/r/remove_digit.cpp`](../../../cpp/r/remove_digit.cpp) |
| Elisa | [`elisa/r/remove_digit.elisa`](../../../elisa/r/remove_digit.elisa) |
| Nim | [`nim/r/remove_digit.nim`](../../../nim/r/remove_digit.nim) |
| Odin | [`odin/r/remove_digit.odin`](../../../odin/r/remove_digit.odin) |
| Rust | [`rust/r/remove_digit.rs`](../../../rust/r/remove_digit.rs) |
| V | [`v/r/remove_digit.v`](../../../v/r/remove_digit.v) |
| Zig | [`zig/r/remove_digit.zig`](../../../zig/r/remove_digit.zig) |
