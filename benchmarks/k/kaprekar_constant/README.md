# Kaprekar constant routine

Apply the four-digit Kaprekar routine until the value reaches 6174, and return the number of iterations.

## Contract

The `i64_array_scalar` input is `[number, max_iterations]`. The number must be in 0 through 9,999 and the iteration limit in 1 through 16. Each step pads the current value to four decimal digits, sorts the digits ascending and descending, then subtracts the smaller arrangement from the larger. Return the iteration count when 6174 is reached, `0` when the starting number is already 6174, and `-1` when the limit expires or the routine reaches zero. Malformed input also returns `-1`.

The pinned function also returns the intermediate sequence. This scalar contract records its iteration count; the sequence is not part of this ABI.

## Source

The pinned Python [`kaprekar_constant.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/kaprekar_constant.py) pads every step to four digits, applies descending-minus-ascending ordering, and stops at 6174, zero, or its iteration limit. The workload uses bounded positive limits and maps source input exceptions to `-1`.

## Workload and recording

[`workload.json`](workload.json) covers the documented examples, the fixed point, repeated-digit inputs, an iteration-limit stop, and malformed bounds.

The shared `i64_array_scalar` runner validates the bounded digit-sort recurrence and checks the declared iteration count for each case.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm kaprekar_constant --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/k/kaprekar_constant/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/k/kaprekar_constant.c`](../../../c/k/kaprekar_constant.c) |
| C3 | [`c3/k/kaprekar_constant.c3`](../../../c3/k/kaprekar_constant.c3) |
| C++ | [`cpp/k/kaprekar_constant.cpp`](../../../cpp/k/kaprekar_constant.cpp) |
| Elisa | [`elisa/k/kaprekar_constant.elisa`](../../../elisa/k/kaprekar_constant.elisa) |
| Nim | [`nim/k/kaprekar_constant.nim`](../../../nim/k/kaprekar_constant.nim) |
| Odin | [`odin/k/kaprekar_constant.odin`](../../../odin/k/kaprekar_constant.odin) |
| Rust | [`rust/k/kaprekar_constant.rs`](../../../rust/k/kaprekar_constant.rs) |
| V | [`v/k/kaprekar_constant.v`](../../../v/k/kaprekar_constant.v) |
| Zig | [`zig/k/kaprekar_constant.zig`](../../../zig/k/kaprekar_constant.zig) |
