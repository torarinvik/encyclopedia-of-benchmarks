# Three Sum Closest

This benchmark returns the sum of three distinct array positions whose sum is closest to a target, following [TheAlgorithms/C LeetCode 16](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/16.c). The upstream implementation sorts the input in place and uses a two-pointer scan. These ports sort a private copy with portable heapsort so the ABI input remains unchanged.

## Contract

- The packed input is `[target, count, values...]`. The target and each value must fit signed 32-bit; `count` is from 3 through 512 and the packed length must equal `count + 2`.
- The result is the closest three-value sum. If two sums are equally close, return the lower sum, giving every implementation deterministic behavior.
- Invalid input returns `-9000000000000000000`. The input is not modified.
- Sorting takes O(n log n); the two-pointer search takes O(n²). Each implementation uses fixed storage for at most 512 values.

The numeric LeetCode source stem `16` is represented by the alphabetic algorithm name `three_sum_closest` in language folders and the benchmark catalog.

Run `python3 benchmarks/verify_three_sum_closest.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against an independent sorted-pair/binary-search oracle, exhaustive short arrays, signed-boundary inputs, random cases, and the workload.

## Inspected upstream source

- [C — LeetCode `16.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/16.c)
