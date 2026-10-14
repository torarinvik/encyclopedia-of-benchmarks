# Circle Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. C ABI entry point: void circle_sort(int64_t *values, size_t length).

A circle pass compares mirrored elements in each range, recursively applies itself to the two halves, and repeats whole-array passes until none of those comparisons swaps values. Odd-length ranges also compare the center pair used by the inspected implementations. Implementations use portable scalar comparisons and swaps.

## Workload

[workload.json](workload.json) defines deterministic modular-affine input values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001 for lengths 0, 16, 64, 256. The runner restores input before each sample and checks the complete sorted output after timing.

Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py); each timed sample contains one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/c/circle_sort.c](../../../c/c/circle_sort.c) | Local port |
| C3 | [c3/c/circle_sort.c3](../../../c3/c/circle_sort.c3) | Local port |
| C++ | [cpp/c/circle_sort.cpp](../../../cpp/c/circle_sort.cpp) | Local port |
| Elisa | [elisa/c/circle_sort.elisa](../../../elisa/c/circle_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/c/circle_sort.nim](../../../nim/c/circle_sort.nim) | Local port |
| Odin | [odin/c/circle_sort.odin](../../../odin/c/circle_sort.odin) | Local port |
| Rust | [rust/c/circle_sort.rs](../../../rust/c/circle_sort.rs) | Local port |
| V | [v/c/circle_sort.v](../../../v/c/circle_sort.v) | Local port |
| Zig | [zig/c/circle_sort.zig](../../../zig/c/circle_sort.zig) | Local port |

## TheAlgorithms references

This filename candidate appears in 3 source repositories. The inspected references were checked at the pinned commits recorded in the catalog:

- [Python circle_sort.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/circle_sort.py)
- [Java CircleSort.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/CircleSort.java)
