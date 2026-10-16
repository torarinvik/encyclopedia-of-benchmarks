# Two's complement of a binary numeral

Transform the two's-complement bit pattern written as a decimal numeral using
only decimal digits `0` and `1`. The pinned MATLAB function operates on numeric
digits and returns a numeric digit sequence, not a string.

## Contract

- The unary scalar ABI is `int64_t twos_complement_of_binary(int64_t value)`.
- Accepted inputs are `0` through `1,111,111,111,111,111` whose decimal digits
  are all `0` or `1`. Invalid inputs return `-1`.
- Zero returns zero. For a positive bit numeral, preserve the rightmost `1` and
  every trailing zero, invert all more-significant bits, and return the result
  as a decimal integer. Leading zero bits in the result disappear because the
  source returns a number.
- The 16-digit limit preserves exact integer arithmetic in MATLAB's binary64
  numeric type: every valid input and intermediate decimal accumulator stays
  below `2^53`.

For example, `1011` transforms to the bit pattern `0101`, returned as decimal
`101`. `11000` transforms to `01000`, returned as `1000`.

## Workload and source

[`workload.json`](workload.json) covers zero, short bit patterns, trailing
zeros, the exactness boundary, and invalid values. The independent oracle uses
a string bit-pattern transformation rather than the source's decimal-digit
accumulator.

Pinned source: [TheAlgorithms/MATLAB-Octave
`twos_complement_of_binary.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/twos_complement_of_binary.m).

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm twos_complement_of_binary --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/t/twos_complement_of_binary/rust/build.json
python3 benchmarks/verify_scalar.py --algorithms twos_complement_of_binary --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/twos_complement_of_binary.c`](../../../c/t/twos_complement_of_binary.c) |
| C3 | [`c3/t/twos_complement_of_binary.c3`](../../../c3/t/twos_complement_of_binary.c3) |
| C++ | [`cpp/t/twos_complement_of_binary.cpp`](../../../cpp/t/twos_complement_of_binary.cpp) |
| Elisa | [`elisa/t/twos_complement_of_binary.elisa`](../../../elisa/t/twos_complement_of_binary.elisa) |
| Nim | [`nim/t/twos_complement_of_binary.nim`](../../../nim/t/twos_complement_of_binary.nim) |
| Odin | [`odin/t/twos_complement_of_binary.odin`](../../../odin/t/twos_complement_of_binary.odin) |
| Rust | [`rust/t/twos_complement_of_binary.rs`](../../../rust/t/twos_complement_of_binary.rs) |
| V | [`v/t/twos_complement_of_binary.v`](../../../v/t/twos_complement_of_binary.v) |
| Zig | [`zig/t/twos_complement_of_binary.zig`](../../../zig/t/twos_complement_of_binary.zig) |
