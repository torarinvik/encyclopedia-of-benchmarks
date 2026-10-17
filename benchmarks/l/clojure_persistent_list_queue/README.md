# Clojure persistent list queue

This benchmark follows the queue operations in the pinned Clojure
[`list.clj`](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/queue/list.clj).
Clojure lists add with `conj` at the front; the queue therefore stores its
newest value first, removes the oldest value with `drop-last`, and peeks at the
oldest value at the final list position.

## Contract

The ABI is `i64_array_scalar`. Input is
`[operation_count, (opcode, argument)*]`, with 0–256 operations and exact length
`1 + 2 * operation_count`. At most 64 values may be in the queue. Enqueued
values are signed i32 integers. All operations except enqueue require a zero
argument. The maximum valid input length is 513 words; 514 words are parseable
to reject trailing input.

| Opcode | Operation | Result recorded in the trace |
|---:|---|---|
| 0 | `enqueue(value)` | Queue size after enqueue |
| 1 | `dequeue()` | Queue size after dequeue; an empty dequeue leaves the queue unchanged |
| 2 | `peek-queue()` | Oldest value, or `INT64_MIN` when empty (Clojure `nil`) |
| 3 | `empty-queue?()` | 1 when empty, otherwise 0 |

The scalar result is the low 63 bits of FNV-1a-64 over a little-endian trace:
operation count as u16; for each operation, opcode as u8 and its recorded
result as i64; final queue size as u16; then final queue values in
oldest-to-newest order as signed i32 values. The FNV offset basis is
`14695981039346656037` and the prime is `1099511628211`. This wrapper records
queue size after the queue-returning enqueue/dequeue calls, while peek and
empty use their source return values.

Malformed framing, unknown opcodes, nonzero query arguments, non-i32 enqueue
values, or an enqueue past the bounded queue length return `-1`. A null input
pointer also returns `-1`.

The oracle uses a direct oldest-to-newest Python list rather than the source's
reversed persistent-list representation. The workload is
[`workload.json`](workload.json), and the oracle is
[`benchmarks/clojure_persistent_list_queue_oracle.py`](../../clojure_persistent_list_queue_oracle.py).

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm clojure_persistent_list_queue --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm clojure_persistent_list_queue
python3 benchmarks/verify_i64_array_scalar.py --algorithm clojure_persistent_list_queue --languages c
~~~

## Ports

- C: [`c/l/clojure_persistent_list_queue.c`](../../../c/l/clojure_persistent_list_queue.c)
- C3: [`c3/l/clojure_persistent_list_queue.c3`](../../../c3/l/clojure_persistent_list_queue.c3)
- C++: [`cpp/l/clojure_persistent_list_queue.cpp`](../../../cpp/l/clojure_persistent_list_queue.cpp)
- Elisa: [`elisa/l/clojure_persistent_list_queue.elisa`](../../../elisa/l/clojure_persistent_list_queue.elisa)
- Nim: [`nim/l/clojure_persistent_list_queue.nim`](../../../nim/l/clojure_persistent_list_queue.nim)
- Odin: [`odin/l/clojure_persistent_list_queue.odin`](../../../odin/l/clojure_persistent_list_queue.odin)
- Rust: [`rust/l/clojure_persistent_list_queue.rs`](../../../rust/l/clojure_persistent_list_queue.rs)
- V: [`v/l/clojure_persistent_list_queue.v`](../../../v/l/clojure_persistent_list_queue.v)
- Zig: [`zig/l/clojure_persistent_list_queue.zig`](../../../zig/l/clojure_persistent_list_queue.zig)

## Pinned source

The benchmark pins `src/data_structures/queue/list.clj` at Clojure commit
`a9c5bec14928cb22fd4d69e951edf5bd15e16a18`, namespace
`data-structures.queue.list`.

The catalog also lists a C queue candidate, but that implementation is invalid
because its length is uninitialized and its constructors are unsafe. This
benchmark uses only the Clojure queue semantics.
