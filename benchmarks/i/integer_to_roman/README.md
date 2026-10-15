# Integer to Roman Numeral

Convert a positive integer to its canonical uppercase Roman numeral using the standard subtractive pairs `IV`, `IX`, `XL`, `XC`, `CD`, and `CM`.

## Contract

- Input is a signed 64-bit integer from 1 through 3,999.
- Output is the corresponding canonical uppercase Roman numeral as ASCII bytes.
- Inputs outside this range return -1. An output buffer shorter than the numeral returns -2, and errors leave the output buffer untouched.

## Workload and verification

[`workload.json`](workload.json) covers the subtractive boundaries, representative values, the maximum value, and invalid inputs. [`benchmarks/verify_i64_scalar_bytes_output.py`](../../verify_i64_scalar_bytes_output.py) checks all nine ports against an independent greedy conversion oracle for every input from 0 through 4,096, deterministic random values, signed boundaries, invalid values, and output-capacity boundaries.

## Reviewed TheAlgorithms sources

The pinned C [LeetCode 12 implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/12.c), Java [`IntegerToRoman`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/IntegerToRoman.java), Go [`inttoroman`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/conversion/inttoroman.go), JavaScript [`DecimalToRoman`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/DecimalToRoman.js), C++ [`decimal_to_roman_numeral`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/decimal_to_roman_numeral.cpp), and Python [`int_to_roman`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/roman_numerals.py) sources implement this conversion. Their range and output APIs differ; the benchmark standardizes on values 1 through 3,999 and length-prefixed ASCII output. The pinned Dart `integer_to_roman` source prints symbols but returns an empty list, so it does not produce the conversion result.

## Implementations

All nine portable implementations use the shared scalar-to-bytes ABI.
