# Dutch National Flag Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. C ABI entry point: void dutch_national_flag_sort(int64_t *values, size_t length).

This in-place three-way partition sorts keys in linear time using constant extra space. The contract is restricted to the three signed integer keys 0, 1, and 2; an unrecognized key is outside the workload domain. Implementations use portable scalar integer operations and do not require CPU-specific instructions.

## Workload

[workload.json](workload.json) defines deterministic input values by the formula values[index] = (index * 2) mod 3 for lengths 0, 16, 256, 1024, 4096. The sort runner generates input and a qsort reference before timing, restores the original input before each sample, and validates the complete output afterward.

Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py); each timed sample contains one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/d/dutch_national_flag_sort.c](../../../c/d/dutch_national_flag_sort.c) | Local port |
| C3 | [c3/d/dutch_national_flag_sort.c3](../../../c3/d/dutch_national_flag_sort.c3) | Local port |
| C++ | [cpp/d/dutch_national_flag_sort.cpp](../../../cpp/d/dutch_national_flag_sort.cpp) | Local port |
| Elisa | [elisa/d/dutch_national_flag_sort.elisa](../../../elisa/d/dutch_national_flag_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/d/dutch_national_flag_sort.nim](../../../nim/d/dutch_national_flag_sort.nim) | Local port |
| Odin | [odin/d/dutch_national_flag_sort.odin](../../../odin/d/dutch_national_flag_sort.odin) | Local port |
| Rust | [rust/d/dutch_national_flag_sort.rs](../../../rust/d/dutch_national_flag_sort.rs) | Independent portable implementation; TheAlgorithms reference below |
| V | [v/d/dutch_national_flag_sort.v](../../../v/d/dutch_national_flag_sort.v) | Local port |
| Zig | [zig/d/dutch_national_flag_sort.zig](../../../zig/d/dutch_national_flag_sort.zig) | Local port |

## TheAlgorithms references

The candidate appears in 4 source repositories. These reference implementations were inspected at the pinned commits recorded in the catalog:

- [Rust dutch_national_flag_sort.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/dutch_national_flag_sort.rs)
- [Python dutch_national_flag_sort.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/dutch_national_flag_sort.py)
