# Cursor Linked List

This benchmark ports the pinned Java array-backed singly linked list. Its 100 cursor slots include slot 0 as the free-list sentinel, leaving 99 allocatable nodes. The input is a bounded sequence of append, remove, remove-by-index, get, and index-of operations; the output includes query results and the full cursor-space state so allocation and free-list reuse remain observable.

## Contract

- Input is `[operation_count, (opcode, int32_argument)...]`, with 0 through 64 operations. Opcodes are `0=append`, `1=remove first matching value`, `2=removeByIndex`, `3=get`, and `4=indexOf`.
- All arguments are signed 32-bit integers. Remove operations must refer to a present value in a nonempty list; remove-by-index must use a valid logical index. Get and index-of may miss. The operation limit keeps the cursor allocator below its 99-node capacity.
- `removeByIndex` follows the Java method composition: it gets the value at the requested index, then removes the first equal value. Duplicate values can therefore remove an earlier occurrence.
- Output is `[query_count, (found, query_value)..., head_index, count, (occupied, element_or_zero, next_index) for cursor slots 0 through 99]`, encoded as little-endian signed 64-bit values. Missing get/index-of results are `(0, 0)`; successful queries are `(1, value_or_index)`. The function returns the output byte count, `-1` for malformed or invalid traces, and `-2` for insufficient output capacity.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm cursor_linked_list --language cpp --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/cursor_linked_list/cpp/build.json
```

## Pinned source

- Java [`CursorLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/CursorLinkedList.java)
