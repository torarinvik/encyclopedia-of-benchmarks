# Gnome sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Equal values retain their relative order. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void gnome_sort(int64_t *values, size_t length);
```

The algorithm walks adjacent pairs, moving forward when they are ordered and swapping backward when they are not. The local versions begin at the first valid pair, so they do not read before the start of the array.

## Workload

[`workload.json`](workload.json) defines a deterministic modular-affine input `values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001` at lengths `0`, `16`, `256`, and `1,024`. The sort runner restores the same input before each timed call and checks the complete output against a reference sorted outside timing.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Each sample times one in-place sort.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/g/gnome_sort.c`](../../../c/g/gnome_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/g/gnome_sort.c3`](../../../c3/g/gnome_sort.c3) | Local port |
| C++ | [`cpp/g/gnome_sort.cpp`](../../../cpp/g/gnome_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/g/gnome_sort.elisa`](../../../elisa/g/gnome_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/g/gnome_sort.nim`](../../../nim/g/gnome_sort.nim) | Local port |
| Odin | [`odin/g/gnome_sort.odin`](../../../odin/g/gnome_sort.odin) | Local port |
| Rust | [`rust/g/gnome_sort.rs`](../../../rust/g/gnome_sort.rs) | Local port |
| V | [`v/g/gnome_sort.v`](../../../v/g/gnome_sort.v) | Local port |
| Zig | [`zig/g/gnome_sort.zig`](../../../zig/g/gnome_sort.zig) | Local port |

The inspected C reference uses a signed index and can access `position - 1` before the first element. The C++ version checks the start explicitly. These ports use a valid-pair starting position with the same gnome-sort walk.

## TheAlgorithms references

- [C `gnome_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/gnome_sort.c)
- [C++ `gnome_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/gnome_sort.cpp)
