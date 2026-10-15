# Pow(x, n)

This benchmark computes a binary64 base raised to a signed 32-bit integer exponent by repeated squaring. It corresponds to LeetCode problem 50, Pow(x, n), and is kept separate from `binary_exponentiation`, whose operands and result use exact integer arithmetic.

## Contract

- The base is a finite binary64 value strictly between -100 and 100. The exponent is any signed 32-bit integer.
- A zero base is used only with a positive exponent. Valid outputs lie in `[-10000, 10000]`.
- Exponent zero returns `1.0`. Negative exponents return the reciprocal of the positive power.
- `INT32_MIN` is handled without negating it in 32-bit arithmetic, using the source's `1 / (powPositive(x, INT32_MAX) * x)` form.
- Results use IEEE-754 binary64 arithmetic. Comparisons allow relative error up to `1e-12` for nonzero results; zero results must match both zero value and sign bit.

The ports scan exponent bits from most significant to least significant and square the accumulated result, multiplying by the base when the next bit is set. This preserves the repeated-squaring operation order and uses `O(log |n|)` time and constant auxiliary space.

## Reviewed source

The pinned C source uses recursive repeated squaring, computes reciprocals for negative exponents, and has a special case for `INT_MIN`.

- [TheAlgorithms/C `50.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/50.c)

## Workload and recording

`workload.json` covers positive, negative, and zero bases; positive and negative exponents; reciprocal results; signed zero; output boundaries; and both signed 32-bit exponent boundaries. Each recorded result contains its binary64 bit pattern as well as its numeric value.

Build with the `float64_i32` ABI family, then record with `benchmarks/run_float64_i32.py`:

```sh
python3 benchmarks/build_abi.py --family float64_i32 --algorithm powx_n --language rust
python3 benchmarks/run_float64_i32.py --build-manifest build/float64_i32/p/powx_n/rust/build.json
```
