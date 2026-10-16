# Dynamic array operation trace

This benchmark runs a bounded sequence of append, update, read, and size operations over a resizable signed 64-bit array. It follows the common observable API in the pinned C, Java, and Python candidates.

## Contract

The input is `[operation_count, operation_records...]`, with at most 128 operations and 64 stored elements. Each record begins with an opcode:

| Opcode | Record | Behavior |
| --- | --- | --- |
| `0` | `[0, value]` | Append one signed 64-bit value. |
| `1` | `[1, index, value]` | Replace an existing element. |
| `2` | `[2, index]` | Read an existing element and append it to the query results. |
| `3` | `[3]` | Append the current size to the query results. |

The output is a sequence of signed 64-bit words in little-endian order: `[query_count, query_results..., final_size, final_values...]`. A valid call returns the number of output words. Malformed traces, unknown operations, out-of-range indices, or attempts to exceed 64 elements return `-1`; insufficient output capacity returns `-2` without publishing output.

The bounded backing store starts at capacity 16 and doubles to at most 64, copying all current elements on each growth. The nine ports use fixed local storage with two backing buffers to model those copies without a per-call allocator. Initial capacity 16 matches the C and Java defaults; the Python source starts at capacity 1. Capacity is not exposed by the shared operation contract.

## Source normalization

The pinned [C implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/dynamic_array/dynamic_array.c) provides `add`, `put`, and `get`; [its header](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/dynamic_array/dynamic_array.h) exposes the size field. Its initializer does not initialize that size field, so the benchmark defines the intended initial state as empty. C's `put` replaces only an existing element. Java's [`DynamicArray`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/dynamicarray/DynamicArray.java) provides `add`, `put`, `get`, and `getSize`, but `put` can also extend the array to a later index; this benchmark restricts it to an existing index to match C and Python. The pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/dynamic_array.py) provides `append`, `get`, indexed assignment, and `len`.

Removal, iteration, string formatting, custom capacity changes, and membership operations are outside the common subset. In particular, C's `contains` checks an index against a size while Java's `contains` searches for a value. This is a dynamic-array operation trace, distinct from the fixed-capacity circular [`queue`](../../q/queue/README.md) and from array transformation algorithms such as rotation. The pinned Clojure [`dynamic_array/core.clj`](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/dynamic_array/core.clj) shares append, get, size, and indexed update behavior; its remove, pop, and formatting helpers are outside this trace.

[`workload.json`](workload.json) covers empty state, mixed reads and writes, signed values, two growth boundaries, invalid records and indices, the element limit, and insufficient output capacity.

The shared `i64_array_bytes_output` runner includes the source oracle for this operation trace; its generic workspace check supplies the insufficient-capacity result.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm dynamic_array --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm dynamic_array
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/dynamic_array.c](../../../c/d/dynamic_array.c) |
| C3 | [c3/d/dynamic_array.c3](../../../c3/d/dynamic_array.c3) |
| C++ | [cpp/d/dynamic_array.cpp](../../../cpp/d/dynamic_array.cpp) |
| Elisa | [elisa/d/dynamic_array.elisa](../../../elisa/d/dynamic_array.elisa) |
| Nim | [nim/d/dynamic_array.nim](../../../nim/d/dynamic_array.nim) |
| Odin | [odin/d/dynamic_array.odin](../../../odin/d/dynamic_array.odin) |
| Rust | [rust/d/dynamic_array.rs](../../../rust/d/dynamic_array.rs) |
| V | [v/d/dynamic_array.v](../../../v/d/dynamic_array.v) |
| Zig | [zig/d/dynamic_array.zig](../../../zig/d/dynamic_array.zig) |
