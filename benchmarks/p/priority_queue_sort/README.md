# Priority queue sort

Sort a bounded sequence by inserting every value into a min-priority queue and draining the queue in ascending order. This preserves the strategy of the pinned Java method, which uses `PriorityQueue<Integer>`.

## Contract

- Input uses the `i64_array_bytes_output` ABI and is exactly `[n, value_0, ..., value_(n-1)]`. `n` is 0–128. Each value is a signed i32 carried in an i64 slot.
- Output contains all values in ascending signed order, encoded as one little-endian signed i32 per value. Duplicates are retained. There is no count header; success returns the number of bytes written, `4*n`, up to 512.
- Invalid or null input returns `-1`. After valid input is checked, a null output pointer or insufficient capacity returns `-2` without writing. This includes a null output for an empty input. A nonnull output with zero capacity succeeds for an empty input and returns 0.
- The pinned Java method returns a null array for null input and returns an empty input array unchanged. The ABI adaptation treats null input as invalid while representing the empty array with `[0]`.

The pinned implementation is [`PriorityQueueSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/PriorityQueueSort.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. It offers each integer to Java's min-priority queue, then polls into the input array until the queue is empty.

`workload.json` covers empty and singleton inputs, duplicates, signed boundaries, the maximum input/output size, malformed frames, null pointers, and output-capacity failures. `benchmarks/priority_queue_sort_oracle.py` uses an independent ascending sort as the reference for the queue's observable order.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/priority_queue_sort.c`](../../../c/p/priority_queue_sort.c) |
| C3 | [`c3/p/priority_queue_sort.c3`](../../../c3/p/priority_queue_sort.c3) |
| C++ | [`cpp/p/priority_queue_sort.cpp`](../../../cpp/p/priority_queue_sort.cpp) |
| Elisa | [`elisa/p/priority_queue_sort.elisa`](../../../elisa/p/priority_queue_sort.elisa) |
| Nim | [`nim/p/priority_queue_sort.nim`](../../../nim/p/priority_queue_sort.nim) |
| Odin | [`odin/p/priority_queue_sort.odin`](../../../odin/p/priority_queue_sort.odin) |
| Rust | [`rust/p/priority_queue_sort.rs`](../../../rust/p/priority_queue_sort.rs) |
| V | [`v/p/priority_queue_sort.v`](../../../v/p/priority_queue_sort.v) |
| Zig | [`zig/p/priority_queue_sort.zig`](../../../zig/p/priority_queue_sort.zig) |
