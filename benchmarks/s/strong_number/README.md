# Strong number

A strong number equals the sum of the factorials of its decimal digits. The benchmark uses the single-value scalar ABI and checks digits directly, computing each digit factorial in a short loop.

## Contract

- Input is a signed 64-bit integer, restricted to the signed 32-bit range accepted by the pinned C source. Values outside `[-2,147,483,648, 2,147,483,647]` return `-1`.
- Negative values return `0`. For nonnegative values, return `1` when the factorial sum of the decimal digits equals the input, and `0` otherwise. The decimal representation of zero is treated as one zero digit, so its digit factorial sum is `0! = 1` and zero is not strong.
- All factorial sums fit signed 32-bit arithmetic: an input has at most ten digits, and each digit factorial is at most `9! = 362,880`.

## Source semantics

The benchmark follows the pinned [TheAlgorithms C source `math/strong_number.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/strong_number.c). Its comment states `0! == 1`, but the code initializes a zero digit's factorial to `0`; this causes `40585` to be misclassified. The source also skips its digit loop for input zero and returns true. The ports honor the documented factorial definition, including zero digits and the input zero case, while preserving the source's negative-input result.

## Workload and build

[`workload.json`](workload.json) includes known strong numbers, zero digits, negative inputs, non-strong values, signed 32-bit boundaries, and values outside the source parameter range. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm strong_number --language c
python3 benchmarks/run_scalar.py --algorithm strong_number
```

The nine implementations are in `c/s/strong_number.c`, `c3/s/strong_number.c3`, `cpp/s/strong_number.cpp`, `elisa/s/strong_number.elisa`, `nim/s/strong_number.nim`, `odin/s/strong_number.odin`, `rust/s/strong_number.rs`, `v/s/strong_number.v`, and `zig/s/strong_number.zig`.
