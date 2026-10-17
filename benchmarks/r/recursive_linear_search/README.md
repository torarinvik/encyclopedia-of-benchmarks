# Recursive Linear Search

Recursively search a bounded integer array and return the target's zero-based index.

## Contract

- ABI: i64_array_scalar.
- Input is [n, target, values...], with exact length n + 2 and 2 <= n <= 64.
- Target and values must fit signed i32. Values must be distinct so the pinned Fortran and Ruby source variants return the same index.
- Return the zero-based index when found or -1 when absent. The Fortran source's one-based result is normalized by subtracting one.
- Invalid framing, a null input pointer, duplicate values, or out-of-range integers return -1.

The recursive ports check both ends of the remaining range on each call, matching the pinned Ruby search; on the distinct-value domain this returns the same normalized index as the pinned Fortran search from the final element backward. Arrays shorter than two are excluded because the pinned Ruby routine raises on a miss in a one-element array and on empty bounds.

## Workload

[workload.json](workload.json) covers targets at both ends and in the middle, absent targets, negative and boundary values, the maximum array size, duplicate rejection, and malformed input. The [oracle](../../recursive_linear_search_oracle.py) returns the unique matching index.

## Implementations

| Language | Source |
| --- | --- |
| C | [C source](../../../c/r/recursive_linear_search.c) |
| C3 | [C3 source](../../../c3/r/recursive_linear_search.c3) |
| C++ | [C++ source](../../../cpp/r/recursive_linear_search.cpp) |
| Elisa | [Elisa source](../../../elisa/r/recursive_linear_search.elisa) |
| Nim | [Nim source](../../../nim/r/recursive_linear_search.nim) |
| Odin | [Odin source](../../../odin/r/recursive_linear_search.odin) |
| Rust | [Rust source](../../../rust/r/recursive_linear_search.rs) |
| V | [V source](../../../v/r/recursive_linear_search.v) |
| Zig | [Zig source](../../../zig/r/recursive_linear_search.zig) |

## Pinned sources

- [Fortran recursive_linear_search.f90](https://github.com/TheAlgorithms/Fortran/blob/c91199703b78bd2181051b01bd5269740e41e121/modules/searches/recursive_linear_search.f90) at c91199703b78bd2181051b01bd5269740e41e121.
- [Ruby recursive_linear_search.rb](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/searches/recursive_linear_search.rb) at bda11bdfd83b7958e1ca98247e5e43100ca88865.

## Build and record

Build with the i64_array_scalar ABI and run benchmarks/run_i64_array_scalar.py for this algorithm.
