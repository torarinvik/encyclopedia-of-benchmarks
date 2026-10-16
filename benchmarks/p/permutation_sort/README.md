# Permutation sort

This package ports the pinned AArch64 permutation-sort program. The source is a complete program with a hard-coded example array; the adapter accepts the array through the benchmark ABI.

## Contract

Input is a raw array of 1 through 8 signed 64-bit integers. Empty arrays and arrays longer than 8 return `-1`; the AArch64 `isSorted` routine assumes a positive element count. Values use the full signed 64-bit range, matching the source's signed comparisons.

For each call, the adapter copies the input into private storage and checks the original order first. If it is not nondecreasing, it generates permutations using the source's iterative Heap order and checks each one until the first nondecreasing array appears. The scalar result is the number of candidate arrays checked, including the original array. A sorted input and a singleton therefore return 1. Repeated values still generate position permutations, including duplicate value arrangements, just as the source does.

The eight-element cap bounds the search at 8! = 40,320 candidates. The independent oracle [permutation_sort_oracle.py](../../permutation_sort_oracle.py) reproduces the initial check and Heap permutation order.

The candidate also has a MATLAB `permutationSort` implementation, but it enumerates a different permutation order and does not report the candidate count. This package follows the explicitly pinned AArch64 behavior.

## Workload

[workload.json](workload.json) covers already sorted and unsorted inputs, signed extremes, duplicates, singleton input, the maximum length, and invalid lengths.

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm permutation_sort --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_scalar.py --algorithm permutation_sort

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/permutation_sort.c](../../../c/p/permutation_sort.c) |
| C3 | [c3/p/permutation_sort.c3](../../../c3/p/permutation_sort.c3) |
| C++ | [cpp/p/permutation_sort.cpp](../../../cpp/p/permutation_sort.cpp) |
| Elisa | [elisa/p/permutation_sort.elisa](../../../elisa/p/permutation_sort.elisa) |
| Nim | [nim/p/permutation_sort.nim](../../../nim/p/permutation_sort.nim) |
| Odin | [odin/p/permutation_sort.odin](../../../odin/p/permutation_sort.odin) |
| Rust | [rust/p/permutation_sort.rs](../../../rust/p/permutation_sort.rs) |
| V | [v/p/permutation_sort.v](../../../v/p/permutation_sort.v) |
| Zig | [zig/p/permutation_sort.zig](../../../zig/p/permutation_sort.zig) |

## Pinned source

[AArch64 `permutation_sort.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/sorters/permutation_sort.s). Its header credits [Rosetta Code's permutation sort](https://rosettacode.org/wiki/Sorting_algorithms/Permutation_sort) and identifies the source as CC BY-SA 4.0.
