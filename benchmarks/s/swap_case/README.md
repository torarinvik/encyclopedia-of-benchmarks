# Swap case

Toggle the case of ASCII letters in a byte sequence. Uppercase `A` through `Z`
become lowercase and lowercase `a` through `z` become uppercase; every other
7-bit ASCII value, including NUL and whitespace, is preserved. This matches
the pinned F# implementation, whose `IsUpper` and `IsLower` helpers recognize
only those ASCII ranges.

## Contract

- Input is an array of 0 to 4,096 signed 64-bit values, each in `0..127`.
- The output has the same length and contains the case-swapped ASCII bytes.
- Invalid length, null nonempty input, or an out-of-range byte returns `-1`
  without writing output.
- Insufficient output capacity or a null output pointer for nonempty input
  returns `-2` without writing output.
- Empty input succeeds with an empty output, including a null output pointer.

The source's per-character conditions swap only ASCII uppercase and lowercase
letters; the restricted domain makes the F# `char` processing byte-compatible
with the other ports.

## Workload and oracle

[`workload.json`](workload.json) covers empty input, upper/lower/mixed case,
punctuation, whitespace, embedded NUL, maximum length, invalid values, and
insufficient output capacity. The source-derived independent oracle is
[`swap_case_oracle.py`](../../swap_case_oracle.py).

Pinned source: [TheAlgorithms/F-Sharp `SwapCase.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/SwapCase.fs).

## Running and verifying

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm swap_case --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm swap_case
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm swap_case --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/swap_case.c](../../../c/s/swap_case.c) |
| C3 | [c3/s/swap_case.c3](../../../c3/s/swap_case.c3) |
| C++ | [cpp/s/swap_case.cpp](../../../cpp/s/swap_case.cpp) |
| Elisa | [elisa/s/swap_case.elisa](../../../elisa/s/swap_case.elisa) |
| Nim | [nim/s/swap_case.nim](../../../nim/s/swap_case.nim) |
| Odin | [odin/s/swap_case.odin](../../../odin/s/swap_case.odin) |
| Rust | [rust/s/swap_case.rs](../../../rust/s/swap_case.rs) |
| V | [v/s/swap_case.v](../../../v/s/swap_case.v) |
| Zig | [zig/s/swap_case.zig](../../../zig/s/swap_case.zig) |
