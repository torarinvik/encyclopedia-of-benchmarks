# Binary shifts

## Contract

This package preserves the textual binary representations returned by the shared operations in the pinned Python and Rust implementations: logical left shift (operation 0), logical right shift (operation 1), and arithmetic right shift (operation 2). The packed input is `[operation, number, shift]`; the output is the ASCII bytes of the returned string, without a trailing NUL.

`number` is in the signed 32-bit range except `INT32_MIN`, and `shift` is 0 through 31. Logical shifts require a nonnegative number. Invalid packed input returns `-1` and no output. The shift bound keeps Rust's `u32` logical-right shift defined; Python itself accepts larger counts. The excluded `INT32_MIN` avoids the Rust source's overflowing `abs()` in arithmetic right shift.

Logical left shift appends `shift` zero digits to the unprefixed binary digits, keeping the `0b` prefix. Logical right shift removes low-order digits from the unprefixed representation and returns `0b0` when the count reaches its width. Arithmetic right shift follows the source's finite textual sign-extension procedure, including its sign-prefixed width: nonnegative values start with `0` followed by their ordinary binary digits; negative values use the source's complement construction based on the bit length of the magnitude. The arithmetic result repeats that representation's first digit for the shift count, then retains the remaining prefix. This output is intentionally a string-format algorithm, not simply an integer shift.

The pinned Python source raises `ValueError` for negative logical-shift operands/counts. The pinned Rust source returns errors for those cases and also has an arithmetic-left operation absent from Python. This benchmark exposes only the three operations present in both sources and maps invalid ABI inputs to `-1`.

Existing `arithmetic_left_shift`, `arithmetic_right_shift`, and `logical_right_shift` packages return numeric fixed-width shift results. Their contracts differ from these source methods' variable-width `0b...` strings.

## Workload and recording

[`workload.json`](workload.json) covers zero, sign extension, representative shifts, source width boundaries, and invalid packed values. The shared recorder computes and checks the source-style ASCII output byte for byte.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_shifts --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binary_shifts/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_shifts.c`](../../../c/b/binary_shifts.c) |
| C3 | [`c3/b/binary_shifts.c3`](../../../c3/b/binary_shifts.c3) |
| C++ | [`cpp/b/binary_shifts.cpp`](../../../cpp/b/binary_shifts.cpp) |
| Elisa | [`elisa/b/binary_shifts.elisa`](../../../elisa/b/binary_shifts.elisa) |
| Nim | [`nim/b/binary_shifts.nim`](../../../nim/b/binary_shifts.nim) |
| Odin | [`odin/b/binary_shifts.odin`](../../../odin/b/binary_shifts.odin) |
| Rust | [`rust/b/binary_shifts.rs`](../../../rust/b/binary_shifts.rs) |
| V | [`v/b/binary_shifts.v`](../../../v/b/binary_shifts.v) |
| Zig | [`zig/b/binary_shifts.zig`](../../../zig/b/binary_shifts.zig) |

## TheAlgorithms references

- Python [`binary_shifts.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/binary_shifts.py)
- Rust [`binary_shifts.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/bit_manipulation/binary_shifts.rs)
