# Maximum Bags With Full Capacity

Count how many bags can be filled by spending additional rocks on the smallest remaining capacities first, following the greedy sorting strategy in pinned C LeetCode 2279.

## Contract

- The benchmark ABI packs the input as `[additional_rocks, bag_count, capacities..., rocks...]`. Ports compute each remaining capacity as `capacity[i] - rocks[i]`.
- Input length is 2 through 16,384 values, representing 0 through 8,191 bags. The budget is in `0..1,000,000,000`, capacities are in `1..100,000`, and each rock count is in `0..capacity[i]`.
- Invalid inputs return `-1`. Input is read only.
- Implementations compute the deficits into a local work array, heap-sort them in ascending order, then fill the affordable prefix. Time is O(n log n); auxiliary space is bounded by the fixed 8,191-entry work array. The bag limit keeps that array below C3’s 64 KiB stack-object ceiling.

## Workload and verification

[`workload.json`](workload.json) covers empty bags, already-full bags, tight budgets, varied deficits, invalid values, and a 512-bag input. [`benchmarks/verify_maximum_bags_with_full_capacity.py`](../../verify_maximum_bags_with_full_capacity.py) checks all nine ports against an independent sorted-deficit oracle, including exhaustive small cases and the maximum 8,191-bag input. All nine ports passed 10,373 oracle cases each and recorded thirteen workload cases.

## Upstream source

- [TheAlgorithms/C LeetCode 2279](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2279.c)
