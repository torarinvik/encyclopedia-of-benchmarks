# `list_array` bounded operation trace

This benchmark follows the pinned C++ array-backed list. The trace appends values while the list is unsorted, performs one selection sort, then searches and removes values in the sorted list. Search uses the source's recursive midpoint binary search, so duplicate hits report the midpoint index returned by that search.

## Contract

Input is `[capacity, operation_count, (opcode, argument)*]`. Capacity is 1–16 and the operation count is 1–64. Opcode `0` appends a nonnegative signed-i64 value, opcode `1` sorts and requires argument zero, opcode `2` searches, and opcode `3` removes the searched value. Exactly one sort is required; all inserts precede it and all searches/removals follow it. Inserts cannot exceed capacity.

To keep the pinned unsigned-index code within defined array bounds, each search or removal requires a nonempty list and a query at least as large as the current minimum. Queries in gaps and above the maximum are allowed. Each removal must begin with at least one spare array slot, including when the value is absent; the pinned shift reads `data[top]` before reducing the size. These restrictions also avoid the source's unsigned underflow for a query below the minimum and for searching an empty list.

Output is a little-endian signed-i64 sequence `[lookup_result_count, result..., final_size, final_sorted_values...]`. Search and remove operations each emit the source binary-search index, or `-1` on a miss, in input order. A successful call returns the output byte count. Invalid input returns `-1`; a null or undersized output buffer returns `-2` without writing.

The maximum input has 130 i64 words. The maximum output has 65 words (520 bytes): one insert, one sort, and 62 searches produce 62 lookup results, the final size, and one final value. Each port validates the entire trace before checking output capacity or writing bytes.

See [workload.json](workload.json) and the independent [oracle](../../list_array_oracle.py).

Pinned sources: [TheAlgorithms/C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/list_array.cpp) and [TheAlgorithms/C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/list_array.cpp).

## Language ports

| Language | Source |
|---|---|
| C | [c/l/list_array.c](../../../c/l/list_array.c) |
| C3 | [c3/l/list_array.c3](../../../c3/l/list_array.c3) |
| C++ | [cpp/l/list_array.cpp](../../../cpp/l/list_array.cpp) |
| Elisa | [elisa/l/list_array.elisa](../../../elisa/l/list_array.elisa) |
| Nim | [nim/l/list_array.nim](../../../nim/l/list_array.nim) |
| Odin | [odin/l/list_array.odin](../../../odin/l/list_array.odin) |
| Rust | [rust/l/list_array.rs](../../../rust/l/list_array.rs) |
| V | [v/l/list_array.v](../../../v/l/list_array.v) |
| Zig | [zig/l/list_array.zig](../../../zig/l/list_array.zig) |
