# Binary Heap Indexed Operations

This benchmark ports the bounded `MinHeap` operation set from the pinned [TheAlgorithms/C-Plus-Plus source](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/binaryheap.cpp) and its duplicate [C-Plus-Plus-1 source](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/binaryheap.cpp). It covers insertion, root observation/extraction, and the source's index-based `decreaseKey` and `deleteKey`. The existing `binary_heap_min_push_peek_pop` package covers the insert/peek/extract subset and does not exercise indexed updates or the source capacity behavior.

## Contract

The `i64_array_bytes_output` ABI accepts `[capacity, operation_count, (operation, arg1, arg2)...]`. Capacity is 1..256, operation count is 0..512, and the array length must equal `2 + 3 * operation_count`. Keys must fit signed 32-bit integers. Each operation is one of:

| Code | Operation | Arguments | Result |
| --- | --- | --- | --- |
| 0 | `insertKey(key)` | `arg1=key`, `arg2=0` | Insert unless the heap is at capacity; a full heap ignores the insertion, as the source does. |
| 1 | `getMin()` | both zero | Append the current root. Requires a nonempty heap. |
| 2 | `extractMin()` | both zero | Append and remove the root; an empty heap appends `INT32_MAX`, matching the source. |
| 3 | `decreaseKey(index, new_key)` | zero-based current array index and new key | Replace the indexed key and bubble up while its parent is strictly greater. `new_key` must be no greater than the current key. |
| 4 | `deleteKey(index)` | zero-based current array index, `arg2=0` | Set the indexed key to `INT32_MIN`, bubble it up, then extract the root, matching the source implementation. |

Indices refer to the heap's current internal array after all preceding operations. `getMin` on an empty heap and an out-of-range index violate the operation preconditions. Invalid array shapes, keys, operation codes, or precondition violations return `-1`; insufficient output capacity returns `-2`. Successful calls return the number of output bytes written. Observed keys are encoded as signed 64-bit little-endian values in observation order. The source prints a message when insertion overflows; the ports omit that side effect while preserving the unchanged heap state.

Insertion and indexed decrease use the source's strict `parent > child` comparison. Extraction checks the left child before the right child and only switches to a child with a strictly smaller key, preserving the source's tie behavior. Each operation takes O(log n) time; the bounded heap uses O(256) storage and output uses O(operation_count) space.

See `workload.json` for representative update, delete, capacity, empty-extraction, malformed-input, and output-capacity cases.
