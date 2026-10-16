# Generic heap

The pinned Java `GenericHeap<T>` is a max heap ordered by `Comparable.compareTo`. It supports insertion, maximum lookup, maximum removal, size and empty queries, plus `updatePriority(item)`, which finds the stored item's array index and calls `upHeapify` only. The latter method assumes the caller has already mutated the item's comparison priority.

This bounded cross-language contract represents each item by a unique stable integer ID and a mutable signed 32-bit priority. IDs model the stable equality/hash identity used by the source's index map; the comparator orders by priority. Duplicate IDs are outside the contract. Updating an item sets its priority and reproduces the source's upward-only repair, including its behavior if a priority is lowered.

## Input and output

The `i64_array_scalar` input is `[operation_count, (opcode, item_id, priority)*]`, with at most 256 operations and 128 live items. IDs are 0–4095 and priorities are signed 32-bit values. Opcode 0 inserts a previously unused ID and priority; 1 observes the maximum item; 2 removes the maximum; 3 updates a present ID's priority and up-heapifies; 4 returns size; and 5 returns the empty predicate. The unused ID and priority fields for 1, 2, 4 and 5 must be zero. Empty lookup/removal and updates to absent items are invalid, matching the source's exception/precondition boundary; malformed input returns `-1`.

The result is signed FNV-1a-64 over observations in order. Lookup and removal each hash the returned item's ID and priority. Size and empty queries hash one integer. An empty trace returns the offset basis interpreted as signed i64.

Run `python3 benchmarks/verify_generic_heap.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports.
