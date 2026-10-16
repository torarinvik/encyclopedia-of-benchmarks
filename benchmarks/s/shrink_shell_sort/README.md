# Shrink Shell sort

This benchmark preserves the pinned Python implementation's Shell sort gap sequence. The initial gap is the input length; each pass reduces it using `int(gap / 1.3)`, then performs a gapped insertion sort. The final pass uses gap 1.

## Contract

Sort signed 64-bit integers in ascending order in place. Stability is not promised. The workload covers lengths 0, 1, 16, 256, and 1,024 with deterministic modular-affine values.

Use the shared `sort` ABI and [`benchmarks/run_sort.py`](../../run_sort.py). Build with `python3 benchmarks/build_abi.py --family sort --algorithm shrink_shell_sort --language rust`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/shrink_shell_sort.c`](../../../c/s/shrink_shell_sort.c) |
| C3 | [`c3/s/shrink_shell_sort.c3`](../../../c3/s/shrink_shell_sort.c3) |
| C++ | [`cpp/s/shrink_shell_sort.cpp`](../../../cpp/s/shrink_shell_sort.cpp) |
| Elisa | [`elisa/s/shrink_shell_sort.elisa`](../../../elisa/s/shrink_shell_sort.elisa) |
| Nim | [`nim/s/shrink_shell_sort.nim`](../../../nim/s/shrink_shell_sort.nim) |
| Odin | [`odin/s/shrink_shell_sort.odin`](../../../odin/s/shrink_shell_sort.odin) |
| Rust | [`rust/s/shrink_shell_sort.rs`](../../../rust/s/shrink_shell_sort.rs) |
| V | [`v/s/shrink_shell_sort.v`](../../../v/s/shrink_shell_sort.v) |
| Zig | [`zig/s/shrink_shell_sort.zig`](../../../zig/s/shrink_shell_sort.zig) |

## Pinned source

- [Python `shrink_shell_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/shrink_shell_sort.py)
