# Skew heap

This package specializes the min-priority behavior of TheAlgorithms/Python's
pinned [`SkewHeap`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/skew_heap.py)
with a bounded integer operation trace. The source's merge keeps the smaller
root, insertion merges a singleton, and removal merges the old root's children.

## Contract

Input is `[operation_count, (opcode, argument)*]`, with 0–64 operation pairs
and exact length `1 + 2 * operation_count` (129 valid words; 130 values are
parseable so trailing data can be rejected). The trace supports:

- `0, value`: insert a signed 32-bit value.
- `1, 0`: return the minimum without removing it.
- `2, 0`: remove and return the minimum.
- `3, 0`: iterate the heap and emit all current values in ascending order.
- `4, 0`: clear the heap.
- `5, 0`: emit 1 when empty and 0 otherwise.

At most 32 values may be live in the heap. Duplicates are preserved. Every
non-insert operation requires a zero argument. An empty `top` or `pop` raises
the source's `IndexError`; the wrapper treats either as an invalid trace. The
empty-state query remains valid and returns 1. Any invalid opcode, argument,
bound, live-value overflow, empty `top`/`pop`, or malformed trace returns `-1`
before output checks and writes nothing.

Insert and clear emit no result. `top`, `pop`, and `is_empty` emit one signed
64-bit value. Iteration matches `list(heap)`: it drains through repeated
minimum removals, records the ascending values, reinserts the snapshot in that
order, and emits the values. The tree shape may change, but the heap contents
remain the same. The source swaps merge roots only when the first root is
strictly greater, so equal roots keep the first root. Results from all query
operations are concatenated in trace order and encoded as little-endian signed
64-bit integers.

The result and output capacity are both measured in bytes. A null output
pointer returns `-2`, even for a trace that emits no bytes. A nonnull buffer
with capacity zero succeeds when no result bytes are required; otherwise a
capacity below the required byte count returns `-2`. Output errors write
nothing. The maximum trace output is 1,024 values, or 8,192 bytes: 32 inserts
followed by 32 iterations emit the full heap on each iteration.

The independent sorted-multiset oracle is
[`benchmarks/skew_heap_oracle.py`](../../skew_heap_oracle.py); workload fixtures
are in [`workload.json`](workload.json).

## Source

The source is pinned to TheAlgorithms/Python commit
`e1a2a8b016001309a73d5fec4818c35cca139795`, path
`data_structures/heap/skew_heap.py`, class `SkewHeap`.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/skew_heap.c`](../../../c/s/skew_heap.c) |
| C3 | [`c3/s/skew_heap.c3`](../../../c3/s/skew_heap.c3) |
| C++ | [`cpp/s/skew_heap.cpp`](../../../cpp/s/skew_heap.cpp) |
| Elisa | [`elisa/s/skew_heap.elisa`](../../../elisa/s/skew_heap.elisa) |
| Nim | [`nim/s/skew_heap.nim`](../../../nim/s/skew_heap.nim) |
| Odin | [`odin/s/skew_heap.odin`](../../../odin/s/skew_heap.odin) |
| Rust | [`rust/s/skew_heap.rs`](../../../rust/s/skew_heap.rs) |
| V | [`v/s/skew_heap.v`](../../../v/s/skew_heap.v) |
| Zig | [`zig/s/skew_heap.zig`](../../../zig/s/skew_heap.zig) |

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm skew_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm skew_heap
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm skew_heap --languages rust
~~~
