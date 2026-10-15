# Deficient number

This benchmark checks whether the sum of a number's positive proper divisors
is strictly smaller than the number.

## Contract

- The unary scalar input is a signed 64-bit integer.
- Inputs `n <= 0` return `0`, matching the pinned Python source.
- Inputs in `1..=100,000,000` return `1` when the proper-divisor sum is less
  than `n`, and `0` otherwise. In particular, `1` is deficient.
- Positive inputs above `100,000,000` return `-1` because they are outside the
  shared bounded workload.

The ports preserve the source's factor-pair scan: start the proper-divisor sum
at one, inspect divisors from two through the square root, and add both members
of each factor pair without counting a square root twice. The source uses
Python's arbitrary-precision integers. The benchmark bound also keeps the
accumulator below signed 32-bit range: the sum of proper divisors is bounded
above by `n * H_n`, and `100,000,000 * (1 + ln(100,000,000))` is below
`1,943,000,000`.

This is the deficient-number predicate, where the divisor sum is less than the
input. It is distinct from the existing abundant-number and perfect-number
predicates. The pinned source names the function `is_deficient_number`; the
benchmark exports it under the catalog candidate name `deficient_numbers`.

## Pinned source

- [Python `deficient_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/deficient_numbers.py)

## Workload and build

[`workload.json`](workload.json) uses the unary `scalar` ABI and covers source
behavior for nonpositive inputs, one, deficient and nondeficient values,
square-factor handling, the upper bound, and out-of-range values. Build and
record with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm deficient_numbers --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/d/deficient_numbers/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/d/deficient_numbers.c`](../../../c/d/deficient_numbers.c) |
| C3 | [`c3/d/deficient_numbers.c3`](../../../c3/d/deficient_numbers.c3) |
| C++ | [`cpp/d/deficient_numbers.cpp`](../../../cpp/d/deficient_numbers.cpp) |
| Elisa | [`elisa/d/deficient_numbers.elisa`](../../../elisa/d/deficient_numbers.elisa) |
| Nim | [`nim/d/deficient_numbers.nim`](../../../nim/d/deficient_numbers.nim) |
| Odin | [`odin/d/deficient_numbers.odin`](../../../odin/d/deficient_numbers.odin) |
| Rust | [`rust/d/deficient_numbers.rs`](../../../rust/d/deficient_numbers.rs) |
| V | [`v/d/deficient_numbers.v`](../../../v/d/deficient_numbers.v) |
| Zig | [`zig/d/deficient_numbers.zig`](../../../zig/d/deficient_numbers.zig) |
