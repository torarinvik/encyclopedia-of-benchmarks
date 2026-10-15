# Most-significant-bit radix sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. The partitioning is in place and does not promise stability; equal integer values are indistinguishable under this contract.

The C ABI entry point is:

```c
void msd_radix_sort(int64_t *values, size_t length);
```

Each pass partitions a range by the next bit, starting from the most significant bit, then recursively sorts the zero and one partitions. The signed-value key maps the signed order to unsigned bit order without overflowing at `INT64_MIN`. For the fixed 64-bit domain, worst-case time is `O(64n)` and recursion depth is at most 64; auxiliary storage is `O(1)` apart from that bounded call stack.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine values at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores the input before each sample, times one sort call, and checks the complete output.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

All nine implementations use portable integer operations without architecture-specific instructions. The code is a local in-place port, widened from the pinned Python source to support the full signed 64-bit range.

| Language | Source |
| --- | --- |
| C | [`c/m/msd_radix_sort.c`](../../../c/m/msd_radix_sort.c) |
| C3 | [`c3/m/msd_radix_sort.c3`](../../../c3/m/msd_radix_sort.c3) |
| C++ | [`cpp/m/msd_radix_sort.cpp`](../../../cpp/m/msd_radix_sort.cpp) |
| Elisa | [`elisa/m/msd_radix_sort.elisa`](../../../elisa/m/msd_radix_sort.elisa) |
| Nim | [`nim/m/msd_radix_sort.nim`](../../../nim/m/msd_radix_sort.nim) |
| Odin | [`odin/m/msd_radix_sort.odin`](../../../odin/m/msd_radix_sort.odin) |
| Rust | [`rust/m/msd_radix_sort.rs`](../../../rust/m/msd_radix_sort.rs) |
| V | [`v/m/msd_radix_sort.v`](../../../v/m/msd_radix_sort.v) |
| Zig | [`zig/m/msd_radix_sort.zig`](../../../zig/m/msd_radix_sort.zig) |

## TheAlgorithms reference

- [Python `msd_radix_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/msd_radix_sort.py)
