# Queue operation trace

The pinned inventory finds queue candidates in 11 TheAlgorithms repositories. The implementations vary: C, C++, JavaScript, Rust, and Zig include linked queues; Java uses a bounded circular array; PHP and Swift use arrays; TypeScript defines a queue interface; and the Ruby file demonstrates the standard library's `Queue` and `SizedQueue`. The C queue under `data_structures/queue/queue.c` is a standalone linked-list demo, while the graph queue exposes a separate FIFO API. The pinned `circular_queue` candidates from six repositories implement bounded FIFO queues and are aliases of this benchmark; their capacities and error signaling differ. The Python `circular_queue_linked_list` candidate uses a sentinel-based circular doubly linked ring and matches the shared FIFO transitions when configured with capacity 256. The Go `circularqueuearray` candidate also matches the FIFO operations at capacity 256; its `Size()` returns the fixed capacity, so that method is not mapped to the dynamic size query in this contract. The shared benchmark uses a bounded ring buffer so every target language measures the same queue contract. Its storage is not intended to reproduce each upstream representation.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values as `[opcode, payload]` pairs, for up to 512 operations. Opcodes are:

- `0`: enqueue a payload from -1,000,000 through 1,000,000
- `1`: dequeue, with payload zero
- `2`: peek at the front, with payload zero
- `3`: peek at the rear, with payload zero
- `4`: report whether the queue is empty, with payload zero
- `5`: report the queue size, with payload zero

Capacity is 256. Odd-length input, an unknown operation, an out-of-range enqueue value, a nonzero payload for operations 1–5, underflow, overflow, or input longer than 1,024 values returns `-1`. Empty input is valid.

Each dequeue, peek, empty check, and size result contributes `(operation_index + 1) * (observed_value + 1,000,000)` to a checksum. The remaining queue contributes its values from front to rear, weighted by their one-based positions after the operation sequence. Valid results are nonnegative and fit signed 64-bit under these limits.

[`workload.json`](workload.json) contains 20 recorded cases, including a 512-operation trace that fills the queue, removes half of it, and enqueues until full again to exercise ring-buffer wraparound. The independent verifier checks 38,730 traces per implementation: all operation sequences through length five over eight representative operations, deterministic randomized valid and malformed traces, the capacity boundary, and each workload case.

## Implementations

The nine portable implementations are in [`c/q/queue.c`](../../../c/q/queue.c), [`c3/q/queue.c3`](../../../c3/q/queue.c3), [`cpp/q/queue.cpp`](../../../cpp/q/queue.cpp), [`elisa/q/queue.elisa`](../../../elisa/q/queue.elisa), [`nim/q/queue.nim`](../../../nim/q/queue.nim), [`odin/q/queue.odin`](../../../odin/q/queue.odin), [`rust/q/queue.rs`](../../../rust/q/queue.rs), [`v/q/queue.v`](../../../v/q/queue.v), and [`zig/q/queue.zig`](../../../zig/q/queue.zig). They use generic compiler targets and no architecture-specific instructions.

Run `python3 benchmarks/verify_queue.py --elisa-compiler PATH/TO/elisac` to check all nine implementations against the independent FIFO oracle and validate workload records.

## Upstream references

- [C graph queue](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/queue.c) and [standalone C queue demo](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/queue/queue.c)
- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue.hpp), [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue.hpp), and [C++ linked-list queue](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_linkedlist.cpp). The linked-list source matches valid FIFO operations; its empty-dequeue behavior is outside the shared valid-trace domain.
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/Queue.java)
- [Java generic ArrayList-backed queue](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/GenericArrayListQueue.java), which aliases the shared FIFO transitions on valid non-null traces; its ArrayList capacity growth is not exposed, and it has no rear/size query.
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Queue/Queue.js)
- [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/Queue.php)
- [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/queues/queue.rb)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/queue.rs)
- [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/queue/queue.swift)
- [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/queue/queue.ts)
- [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/queue.zig)
- Python circular linked-list queue: [source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/circular_queue_linked_list.py)
- Circular-queue aliases: [Dart](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Queue/Circular_Queue.dart), [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/queues/CircularQueue.java), [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Queue/CircularQueue.js), [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/queues/circular_queue.py), [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/queues/circular_queue.rb), and [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/queue/circular_queue.ts)
- Array-backed queue aliases: [C# bounded circular queue](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Queue/ArrayBasedQueue.cs) and [TypeScript dynamic-array queue](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/queue/array_queue.ts)
- Go circular array queue: [source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/circularqueue/circularqueuearray.go); its `Size()` reports capacity, not current length
