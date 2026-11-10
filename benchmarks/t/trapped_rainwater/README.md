# Trapped Rainwater

The pinned C++ and Rust implementations compute left and right maximum-height arrays, then sum the water held at each position. They use unsigned 32-bit heights and return values. The benchmark uses the same prefix/suffix-maxima method and keeps only the suffix maxima in an array. The forward pass computes each prefix maximum as it is used.

## Contract

- Input is an array of 0–4,096 signed 64-bit heights.
- Each height must be from 0 through 1,000,000.
- Return the total trapped water; inputs with fewer than three heights return 0.
- Return `-1` for invalid heights or lengths. At the maximum length and height, the total is at most 4,094,000,000.
- The implementations use linear time and one local array of unsigned 32-bit suffix maxima. Short profiles use a 16-element buffer. The reverse pass validates heights while filling the buffer.

## Workload and verification

[`workload.json`](workload.json) includes the standard basin examples, monotone and flat profiles, invalid inputs, and a maximum-length basin. [`benchmarks/verify_trapped_rainwater.py`](../../verify_trapped_rainwater.py) checked 22,411 oracle arrays per language, including exhaustive short profiles, seeded random profiles, invalid heights, overlength arrays, and the large basin. All ten ports passed and each recorded all 13 workload cases.

## Upstream sources

- [C LeetCode `42.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/42.c) computes suffix maximum heights and a running prefix maximum; the shared contract also defines empty input.

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/trapped_rainwater.cpp)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/trapped_rainwater.rs)
