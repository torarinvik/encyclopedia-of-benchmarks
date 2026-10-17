# Fixed-list queue operation trace

This benchmark follows the pinned Dart `ListQueue<T>`, which stores up to ten active elements in FIFO order. Enqueue appends at the end; dequeue returns the front item and shifts the remaining ten-slot backing array to the left. The benchmark exposes only enqueue, dequeue, and the active size.

## Contract

- The ABI is `i64_array_bytes_output`. Input is `[operation_count, opcode, enqueue_value_if_needed, ...]`, with 0–64 operations and exact framing. Opcode `0` enqueues a signed-i32 value, `1` dequeues, and `2` queries the size. Enqueue values are signed-i32 values carried in signed-i64 words.
- The queue starts empty and has capacity ten. An enqueue when the queue is already full makes the trace invalid and returns `-1`. Dequeue on an empty queue is valid: the source prints a message and returns null, represented by query kind `3` with value `0`; the queue remains empty. A successful dequeue emits kind `1` and the removed value. A size query emits kind `2` and the current size.
- The output is `[query_count, kind, value, ..., final_size, final_active_values...]`, encoded as little-endian signed-i32 words. Final values appear from front to back. The empty trace `[0]` returns `[0, 0]` in 8 bytes. Sixty-four size or empty-dequeue queries reach the 520-byte output bound.
- The maximum parseable input is 129 signed-i64 words. The largest valid trace is 102 words: ten enqueues followed by 27 dequeue/enqueue pairs, for 37 enqueues across 64 operations. Invalid or null input returns `-1` before output-buffer checks. A null output pointer or insufficient capacity returns `-2` without writing output.

The source's `hasElements()` checks the backing array length, which is always ten, so it does not report whether the queue contains active items and is excluded from the benchmark interface.

The workload is [workload.json](workload.json); its independent oracle is [benchmarks/list_queue_oracle.py](../../list_queue_oracle.py).

Pinned source: [TheAlgorithms/Dart `List_Queue.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Queue/List_Queue.dart) at commit `73da8ab4ea413eee9bf29aa2263157d86060f871`.

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm list_queue --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm list_queue
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm list_queue --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/l/list_queue.c](../../../c/l/list_queue.c) |
| C3 | [c3/l/list_queue.c3](../../../c3/l/list_queue.c3) |
| C++ | [cpp/l/list_queue.cpp](../../../cpp/l/list_queue.cpp) |
| Elisa | [elisa/l/list_queue.elisa](../../../elisa/l/list_queue.elisa) |
| Nim | [nim/l/list_queue.nim](../../../nim/l/list_queue.nim) |
| Odin | [odin/l/list_queue.odin](../../../odin/l/list_queue.odin) |
| Rust | [rust/l/list_queue.rs](../../../rust/l/list_queue.rs) |
| V | [v/l/list_queue.v](../../../v/l/list_queue.v) |
| Zig | [zig/l/list_queue.zig](../../../zig/l/list_queue.zig) |
