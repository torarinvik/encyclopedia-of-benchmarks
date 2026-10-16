# Min-max heap with double-ended operations

This package follows the pinned C# `MinMaxHeap<T>` over natural-order signed 32-bit integers. It supports bulk construction, `Add`, `GetMin`, `GetMax`, `ExtractMin`, `ExtractMax`, and `Count`. Equal values remain separate entries.

## Contract

The `i64_array_bytes_output` ABI receives `[initial_count, initial_values..., operation_count, (opcode, argument)...]`. The initial count is 0 through 64, operation count is 0 through 128, and all values must fit signed 32-bit integers. Each operation is a fixed pair of signed 64-bit integers:

| Opcode | Operation | Argument | Event result |
| --- | --- | --- | --- |
| 0 | `Add(argument)` | signed i32 value | none |
| 1 | `GetMin()` | 0 | minimum value |
| 2 | `GetMax()` | 0 | maximum value |
| 3 | `ExtractMin()` | 0 | removed minimum |
| 4 | `ExtractMax()` | 0 | removed maximum |
| 5 | `Count` | 0 | current count, including zero |

The input length must be exactly `initial_count + 2 + 2 * operation_count` and is at most 322 i64 values. Get and extract operations on an empty heap are invalid; Count on an empty heap returns zero. The final heap contents are returned in ascending order, with duplicates preserved.

Output is a little-endian signed i64 vector `[event_count, event_results..., final_count, final_values_sorted_ascending...]`. Event results appear in operation order; Add emits no result. Success returns the number of output bytes written. Malformed input returns `-1`; null or insufficient output capacity returns `-2` without writing output.

The ports bulk-build the min-max heap, then perform the same double-ended operations with logarithmic insertions and extractions. The final ordering is only an observation of the remaining multiset; the internal heap layout is not compared.

## Workload

[`workload.json`](workload.json) covers empty construction, reuse after extraction, bulk builds, alternating min/max access and extraction, duplicate retention, signed i32 boundaries, and invalid traces.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm min_max_heap_double_ended --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/m/min_max_heap_double_ended/rust/build.json
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/m/min_max_heap_double_ended.c`](../../../c/m/min_max_heap_double_ended.c) |
| C3 | [`c3/m/min_max_heap_double_ended.c3`](../../../c3/m/min_max_heap_double_ended.c3) |
| C++ | [`cpp/m/min_max_heap_double_ended.cpp`](../../../cpp/m/min_max_heap_double_ended.cpp) |
| Elisa | [`elisa/m/min_max_heap_double_ended.elisa`](../../../elisa/m/min_max_heap_double_ended.elisa) |
| Nim | [`nim/m/min_max_heap_double_ended.nim`](../../../nim/m/min_max_heap_double_ended.nim) |
| Odin | [`odin/m/min_max_heap_double_ended.odin`](../../../odin/m/min_max_heap_double_ended.odin) |
| Rust | [`rust/m/min_max_heap_double_ended.rs`](../../../rust/m/min_max_heap_double_ended.rs) |
| V | [`v/m/min_max_heap_double_ended.v`](../../../v/m/min_max_heap_double_ended.v) |
| Zig | [`zig/m/min_max_heap_double_ended.zig`](../../../zig/m/min_max_heap_double_ended.zig) |

## Pinned source

- C# [`MinMaxHeap.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Heap/MinMaxHeap.cs)
