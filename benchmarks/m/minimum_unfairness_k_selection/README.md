# Minimum unfairness by selecting K values

Given an integer array and `K`, choose exactly `K` elements and minimize the difference between the largest and smallest chosen values. The benchmark copies the input values into a bounded work array, sorts them in `O(N log N)` time, then scans all adjacent `K`-element windows in sorted order.

## Contract

- Input is `[N, K, value_0, ..., value_(N-1)]` as signed 64-bit integers, with exact length `N + 2`.
- `2 <= K <= N <= 64`; each value is in `[-1,000,000,000, 1,000,000,000]`.
- Return the minimum possible `maximum(chosen) - minimum(chosen)`, from `0` through `2,000,000,000`. Invalid input returns `-1`.
- The sorted-window method takes `O(N log N)` time and `O(N)` workspace. The only per-call input copy is at most 64 `i64` values (512 bytes); heapsort ports use `O(1)` additional storage, while Rust's standard unstable sort uses logarithmic call-stack space.

After sorting, an optimal selection is a contiguous window of `K` sorted values. For a proposed selected minimum, choosing any larger available element in place of a smaller one cannot reduce the selected maximum; therefore the best set with that minimum consists of it and the next `K - 1` values. Scanning every such window considers an optimum.

This profile does not duplicate [`minimize_deviation_in_array`](../minimize_deviation_in_array/README.md), which changes values under operation constraints before minimizing deviation, or [`dinkelbach_fixed_cardinality_ratio`](../../d/dinkelbach_fixed_cardinality_ratio/README.md), which maximizes a ratio over fixed-size subsets.

## Workload and references

[`workload.json`](workload.json) covers an interior optimum, duplicate values, negative values, the full permitted value span, `K = N`, a maximum-size frame, malformed lengths, and values outside the bounds. The [primary reference](primary_oracle.py) uses sorting and the adjacent-window scan. The independent [endpoint/count reference](independent_oracle.py) enumerates candidate value endpoints and counts how many input values lie within each interval; it does not sort the input or scan sorted windows.

## Sources and rights

- The Codewars [Optimization collection](https://www.codewars.com/collections/optimization-4) is used only to discover the public title “Minimum unfairness of a list/array”; no kata page or content was opened.
- The official [HackerRank Max Min problem](https://www.hackerrank.com/challenges/angry-children/problem) confirms the objective contract of selecting `K` values and minimizing their maximum-minus-minimum difference. Its official editorial is locked and was inaccessible during this audit.
- The sorting and adjacent-window method and its exchange argument are described in Campbell’s [Max Min derivation](https://campbells9.github.io/interviewprep/greedyalgorithms/maxmin/). This is a secondary educational source.

All implementations and references here are clean-room work. The sources are used for title discovery, objective semantics, and algorithm explanation only; no source code, task text, examples, tests, or submissions were copied.

## Implementations

The ten implementation files are listed in [`INVENTORY.md`](INVENTORY.md). Each exports `minimum_unfairness_k_selection` using the repository’s `i64_array_scalar` call shape. The workload is registered in the scalar runner and verifier, which check the package inventory and compare the two references without changing the input array.
