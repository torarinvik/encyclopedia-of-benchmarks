# KeyPriorityQueue

A bounded integer-key priority queue based on the pinned JavaScript `KeyPriorityQueue`. The package preserves its min-heap operations, including strict priority comparisons and its right-child selection on equal child priorities.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[operation_count, records...]`, with at most 32 operations. Push (`0`) and update (`1`) records are `[opcode, key, priority_micro]`; pop (`2`) and is-empty (`4`) records are one word; contains (`3`) is `[3, key]`.
- Records are framed by opcode: push and update consume three words (`opcode, key, priority_micro`); pop and is-empty consume one; contains consumes two. The array must contain exactly the declared number of records with no trailing words. Null input, malformed framing, and out-of-range values return `-1`. Keys and priority micro-units are in `[-1,000,000,000, 1,000,000,000]`; priority is `priority_micro / 1,000,000`. Push requires an inactive key. Update inserts an absent key. Pop on an empty queue and duplicate active-key pushes are invalid. A key can be pushed again after it is popped.
- Each pop, contains, or is-empty operation appends one signed 64-bit output word. The result is the number of output bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2`, without writes. The full input and operation stream are validated before checking output storage. With zero operations, a non-null output pointer and zero capacity succeed with result `0`; a null output pointer returns `-2` even though no bytes are required.
- Equal priorities follow the source's strict comparisons: shift-up only swaps a strictly larger parent, and shift-down chooses the right child when both children are strictly smaller and have equal priorities.

## Workload

[`workload.json`](workload.json) includes queue behavior, update and reinsertion, priority ties, invalid records, and output capacity cases. See the [oracle](../../key_priority_queue_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/key_priority_queue.c`](../../../c/k/key_priority_queue.c) |
| C3 | [`c3/k/key_priority_queue.c3`](../../../c3/k/key_priority_queue.c3) |
| C++ | [`cpp/k/key_priority_queue.cpp`](../../../cpp/k/key_priority_queue.cpp) |
| Elisa | [`elisa/k/key_priority_queue.elisa`](../../../elisa/k/key_priority_queue.elisa) |
| Nim | [`nim/k/key_priority_queue.nim`](../../../nim/k/key_priority_queue.nim) |
| Odin | [`odin/k/key_priority_queue.odin`](../../../odin/k/key_priority_queue.odin) |
| Rust | [`rust/k/key_priority_queue.rs`](../../../rust/k/key_priority_queue.rs) |
| V | [`v/k/key_priority_queue.v`](../../../v/k/key_priority_queue.v) |
| Zig | [`zig/k/key_priority_queue.zig`](../../../zig/k/key_priority_queue.zig) |

## Pinned source

[TheAlgorithms/JavaScript `KeyPriorityQueue`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Heap/KeyPriorityQueue.js) at `5c39e87a9a31f279c60f830ad74a845e4788a517`.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm key_priority_queue --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/k/key_priority_queue/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm key_priority_queue
```
