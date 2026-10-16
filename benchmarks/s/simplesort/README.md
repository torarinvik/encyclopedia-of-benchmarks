# Simple sort

This package ports the pinned Go `Simple` function from `simplesort.go`.

## Contract

Input is a raw array of 0 through 256 signed 64-bit integers, each in `[-1,000,000, 1,000,000]`. Invalid lengths or values return `-1`. Empty and singleton arrays are valid.

The source scans every ordered pair `(i, j)` and swaps the values when `values[i] < values[j]`. This uses non-adjacent swaps and always performs the full quadratic scan; it is not the adjacent-pair bubble-sort procedure. The adapter copies the input, runs that exact loop, and returns `sum((index + 1) * (output[index] + 1,000,001))` for the resulting slice.

The independent oracle is [simplesort_oracle.py](../../simplesort_oracle.py).

## Workload

[workload.json](workload.json) covers empty and singleton inputs, sorted and reversed values, duplicates, negative values, the maximum length, and invalid inputs.

## Build and record

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm simplesort --language rust
    python3 benchmarks/run_i64_array_scalar.py --algorithm simplesort

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/simplesort.c](../../../c/s/simplesort.c) |
| C3 | [c3/s/simplesort.c3](../../../c3/s/simplesort.c3) |
| C++ | [cpp/s/simplesort.cpp](../../../cpp/s/simplesort.cpp) |
| Elisa | [elisa/s/simplesort.elisa](../../../elisa/s/simplesort.elisa) |
| Nim | [nim/s/simplesort.nim](../../../nim/s/simplesort.nim) |
| Odin | [odin/s/simplesort.odin](../../../odin/s/simplesort.odin) |
| Rust | [rust/s/simplesort.rs](../../../rust/s/simplesort.rs) |
| V | [v/s/simplesort.v](../../../v/s/simplesort.v) |
| Zig | [zig/s/simplesort.zig](../../../zig/s/simplesort.zig) |

Pinned source: [TheAlgorithms/Go `simplesort.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/sort/simplesort.go).
