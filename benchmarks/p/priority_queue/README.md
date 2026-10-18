# Min priority queue trace

This benchmark covers the common min-priority-queue behavior shared by the pinned C# heap and Dart sorted-list queue. The trace stores unique signed i32 priorities as the queue items, so each dequeue and front/peek operation returns that priority.

## Contract

The ABI is `i64_array_bytes_output`. Input is a flat command stream: `[operation_count, op, value, op, ...]`, where `0` means enqueue the following priority, `1` means peek/front, and `2` means dequeue. The operation count is 0..64. Enqueued priorities are signed i32 values and must be unique over the entire trace. Every peek or dequeue must occur while the queue is nonempty. The input must contain exactly the words consumed by the declared operation count.

The queue is a min-priority queue. Each peek/front or dequeue appends the smallest currently enqueued priority to the result stream. Serialize every returned value as a signed i32 in little-endian byte order, in operation order. Enqueue operations emit no output. At most 64 retrieval operations are encoded, for a maximum output of 256 bytes.

Malformed commands, duplicate priorities, empty peek/dequeue, out-of-range priorities, or malformed framing return `-1` before output checks. A null output pointer or capacity below the serialized result length returns `-2` without writes.

Unique priorities avoid the C# heap's unspecified tie order and the Dart queue's FIFO tie behavior. This contract excludes the C# descending mode, capacity/collection constructors, `Clear`, and mutable `GetData`; it also excludes Dart's `end` and `clear` APIs. The two source variants remain distinct outside this shared subset.

## Pinned sources

- C# [`PriorityQueue<T>`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/AStar/PriorityQueue.cs): default ascending binary heap using `IComparable<T>`.
- Dart [`PriorityQueue<T>`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Queue/Priority_Queue.dart): ascending sorted list; the benchmark uses each priority as both its item and priority.

See the [workload](workload.json) and [oracle](../../priority_queue_oracle.py).
