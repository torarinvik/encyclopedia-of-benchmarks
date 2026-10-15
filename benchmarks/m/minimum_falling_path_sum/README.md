# Minimum Falling Path Sum

Return the minimum sum of a falling path from the first row through the last row of a square matrix. Each step goes to the same column or one adjacent column in the next row.

## Contract

- The benchmark packs input as `[n, n*n row-major matrix values]`.
- `n` is in `1..100`; each matrix value is in `-100..100`, matching the source problem constraints.
- Invalid packed inputs return `-10001`, outside the valid result range `-10000..10000`. Input is read only.
- Implementations keep one dynamic-programming row plus a next-row buffer. Time is O(n²); auxiliary space is O(n).

## Workload

[`workload.json`](workload.json) covers a single negative cell, both published examples, edge-column transitions, tied paths, and a 100×100 boundary matrix.

## Upstream source

- [TheAlgorithms/C LeetCode 931 at the pinned revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/931.c)
- [LeetCode 931 problem statement and constraints](https://leetcode.com/problems/minimum-falling-path-sum/description/)
