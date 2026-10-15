# Hamming Numbers

Return the first `n` positive 5-smooth numbers in increasing order. Each value has the form `2^i × 3^j × 5^k` for nonnegative exponents; duplicates are omitted.

## Contract

- Input is a one-element signed 64-bit array `[n]`, where `1 ≤ n ≤ 32`. Malformed input returns `-1`; insufficient output capacity returns `-2`.
- Output is the full ordered list of `n` values, each encoded as a little-endian signed 64-bit integer. The function returns the number of values (`n`), and the maximum output size is 256 bytes.
- The source raises `ValueError` for nonpositive `n`; the ABI normalizes that case and other malformed inputs to `-1`.
- The pinned function actually returns the generated list, although its docstring says it returns the last value. The benchmark follows the implementation and its examples.

## Relationship to Nth Ugly Number

Both algorithms use the same canonical `[2, 3, 5]` smooth-number sequence. [`nth_ugly_number`](../../n/nth_ugly_number/README.md) returns one zero-based element from the sequence; this benchmark returns the first `n` elements as a list, matching the Python function's actual result shape. They therefore use separate contracts and output ABIs.

## Source and implementations

The pinned [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/hamming_numbers.py) advances three indices for multiples of 2, 3, and 5 and appends the minimum candidate, producing a strictly increasing list without duplicates. The nine ports use the same recurrence and advance every index that generated each selected value.

## Workload and build

[`workload.json`](workload.json) covers the first value, the source's five-, ten-, and fifteen-element examples, and invalid counts or packed input. The shared byte-output runner uses an independent factorization oracle for the bounded workload.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm hamming_numbers --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/hamming_numbers/rust/build.json
```
