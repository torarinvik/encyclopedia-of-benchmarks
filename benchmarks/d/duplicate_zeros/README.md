# Duplicate Zeros

This benchmark duplicates every zero in a fixed-length integer array, shifting later values right and dropping values beyond the original length.

## Contract

- Input is an array of 0 to 64 integers from 0 through 1,000. Other values or a longer array return `-1`.
- Each zero is duplicated, and the result is truncated to the original length. Return that length.
- Output serializes each result value as a signed 32-bit little-endian integer. An empty input returns 0 and an empty output.
- Insufficient output capacity returns `-2` without writing output.

## Inspected upstream source

The pinned [TheAlgorithms/C LeetCode file `1089.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1089.c) copies the input and writes values back while duplicating zero slots. The shared contract bounds the workload and standardizes the result through a caller-owned output buffer.

## Workload and verification

[`workload.json`](workload.json) covers empty, zero-free, consecutive-zero, truncated-tail, maximum-length, and invalid inputs. [`benchmarks/verify_duplicate_zeros.py`](../../verify_duplicate_zeros.py) exhausts short arrays over a small alphabet, adds deterministic longer arrays, and checks output bytes and capacity handling in all nine languages.

```sh
python3 benchmarks/verify_duplicate_zeros.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_bytes_output` ABI family. Source ports are in `d/` in all nine language directories.
