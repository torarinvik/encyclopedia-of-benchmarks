# Improved Simple sort

This package ports the pinned Go `ImprovedSimple` function from `simplesort.go`, preserving its exact comparison and swap schedule.

## Contract

Input is a raw array of 0 through 256 signed 64-bit integers, each in `[-1,000,000, 1,000,000]`. Invalid lengths or values return `-1`. Empty and singleton arrays are valid.

The source loops over `i = 1..n-1` and `j = 0..n-2`, swapping the current `values[i]` with `values[j]` when `values[i] < values[j]`. The inner loop never uses the final array position as `j`, and there is no early-exit path. Unlike insertion sort, it scans `j` forward through the prefix and later positions and swaps pairs instead of shifting a key backward. For example, `[1, 2, 3, 0]` becomes `[0, 1, 2, 3]`. The adapter preserves those exact loops and returns `sum((index + 1) * (output[index] + 1,000,001))` for the resulting slice.

The independent oracle is [improved_simple_sort_oracle.py](../../improved_simple_sort_oracle.py).

## Workload

[workload.json](workload.json) includes the last-position case above, sorted and reverse inputs, duplicates, signed values, the maximum length, and invalid inputs.

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm improved_simple_sort --language rust
    python3 benchmarks/run_i64_array_scalar.py --algorithm improved_simple_sort

## Implementations

| Language | Source |
| --- | --- |
| C | [c/i/improved_simple_sort.c](../../../c/i/improved_simple_sort.c) |
| C3 | [c3/i/improved_simple_sort.c3](../../../c3/i/improved_simple_sort.c3) |
| C++ | [cpp/i/improved_simple_sort.cpp](../../../cpp/i/improved_simple_sort.cpp) |
| Elisa | [elisa/i/improved_simple_sort.elisa](../../../elisa/i/improved_simple_sort.elisa) |
| Nim | [nim/i/improved_simple_sort.nim](../../../nim/i/improved_simple_sort.nim) |
| Odin | [odin/i/improved_simple_sort.odin](../../../odin/i/improved_simple_sort.odin) |
| Rust | [rust/i/improved_simple_sort.rs](../../../rust/i/improved_simple_sort.rs) |
| V | [v/i/improved_simple_sort.v](../../../v/i/improved_simple_sort.v) |
| Zig | [zig/i/improved_simple_sort.zig](../../../zig/i/improved_simple_sort.zig) |

Pinned source: [TheAlgorithms/Go `simplesort.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/sort/simplesort.go).
