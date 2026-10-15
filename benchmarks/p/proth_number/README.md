# Proth Number Check

Return whether a positive integer is a Proth number. The pinned Python source defines `is_proth_number(number)` by setting `n = number - 1`, counting factors of two in `n`, and checking whether the remaining odd factor is less than `2**count`.

## Contract

- Inputs from `1` through `INT64_MAX` are supported. The source returns false for `1`.
- Zero and negative inputs raise `ValueError` in Python; the scalar benchmark maps those invalid inputs to `-1`.
- Valid Proth numbers return `1`; other positive inputs return `0`.
- The largest possible exponent in the supported input range is 62, so the power-of-two comparison fits signed 64-bit arithmetic. The ports preserve the source's repeated division by two and strict `<` comparison.
- The function uses the unary signed 64-bit scalar ABI and has logarithmic time in the input's power-of-two factor and constant space.

The source file also includes a separate 1-based Proth sequence generator; that routine is outside this benchmark contract. Proth membership is distinct from Mersenne-prime checks, which examine numbers of the form `2^p - 1` and test primality.

The source is the pinned [TheAlgorithms/Python `proth_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/proth_number.py).

Build one port with `python3 benchmarks/build_scalar.py --algorithm proth_number --language LANGUAGE`. The build manifest is written to `build/scalar/p/proth_number/LANGUAGE/build.json`; the workload uses the standard scalar runner interface in [`benchmarks/run_scalar.py`](../../run_scalar.py).
