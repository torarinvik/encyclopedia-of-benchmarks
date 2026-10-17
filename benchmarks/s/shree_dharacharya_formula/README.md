# Shree Dharacharya quadratic formula

This benchmark ports the pinned MATLAB function that computes the two real roots of `a*x² + b*x + c = 0` with the direct quadratic formula.

## Contract

- The `i64_array_bytes_output` input is exactly `[a, b, c]`, with each signed 64-bit coefficient in `[-1,000,000, 1,000,000]`.
- `a` must be nonzero and the discriminant `d = b*b - 4*a*c` must be nonnegative. Inputs with negative discriminant are invalid because the source only prints a message and leaves both output variables unassigned.
- For valid input, return both roots in source order: `(-b + sqrt(d)) / (2*a)`, then `(-b - sqrt(d)) / (2*a)`. A repeated root appears twice.
- Encode the two values as little-endian IEEE-754 binary64. There is no count prefix. Success returns 16 bytes. Invalid input returns `-1`; a null output pointer or capacity below 16 bytes returns `-2` without writing.
- Maximum input length is 3 values and maximum output workspace is 16 bytes. Float comparisons use absolute and relative tolerances of `1e-12`.

The bounded integer coefficients keep the discriminant exact in binary64 and all supported roots finite. The direct formula is preserved to match the source, including its root ordering and repeated-root output arity.

## Pinned source

[TheAlgorithms/MATLAB-Octave `shreeDharacharyaFormula.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/shreeDharacharyaFormula.m) assigns `x1` from the plus-square-root expression and `x2` from the minus-square-root expression when `d >= 0`.

This contract is distinct from [`quadratic_roots`](../q/quadratic_roots/README.md), which returns one root for a repeated root, and from the Dart [`shreedharacharya`](../s/shreedharacharya/README.md), which returns an empty list for a negative discriminant.

## Workload and oracle

[`workload.json`](workload.json) covers integral, repeated, irrational, fractional, zero-constant, and negative-leading-coefficient roots; coefficient bounds; invalid framing, coefficients, and discriminants; and null/short output capacity. The independent [oracle](../../shree_dharacharya_formula_oracle.py) returns the two roots as packed float64 values.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm shree_dharacharya_formula --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/shree_dharacharya_formula/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm shree_dharacharya_formula --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/shree_dharacharya_formula.c`](../../../c/s/shree_dharacharya_formula.c) |
| C3 | [`c3/s/shree_dharacharya_formula.c3`](../../../c3/s/shree_dharacharya_formula.c3) |
| C++ | [`cpp/s/shree_dharacharya_formula.cpp`](../../../cpp/s/shree_dharacharya_formula.cpp) |
| Elisa | [`elisa/s/shree_dharacharya_formula.elisa`](../../../elisa/s/shree_dharacharya_formula.elisa) |
| Nim | [`nim/s/shree_dharacharya_formula.nim`](../../../nim/s/shree_dharacharya_formula.nim) |
| Odin | [`odin/s/shree_dharacharya_formula.odin`](../../../odin/s/shree_dharacharya_formula.odin) |
| Rust | [`rust/s/shree_dharacharya_formula.rs`](../../../rust/s/shree_dharacharya_formula.rs) |
| V | [`v/s/shree_dharacharya_formula.v`](../../../v/s/shree_dharacharya_formula.v) |
| Zig | [`zig/s/shree_dharacharya_formula.zig`](../../../zig/s/shree_dharacharya_formula.zig) |
