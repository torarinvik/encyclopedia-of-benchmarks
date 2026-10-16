# Binomial Heap

This package exposes the observable min-priority-queue behavior of the pinned Python binomial heap through a bounded operation trace. Each implementation uses rank-indexed binomial-tree roots and links equal-rank trees on insertion and after removing the minimum. Results compare query values, not internal tree shape.

## Contract

Input is `[operation_count, (opcode, argument)*]`, where the operation count is 0 to 128 and the input length is exactly `1 + 2 * operation_count`:

- `0, value`: insert a signed 32-bit value.
- `1, 0`: read the minimum without removing it.
- `2, 0`: remove and return the minimum.
- `3, 0`: return 1 if empty, otherwise 0.

Duplicate values are allowed and preserved. The pinned `peek()` and `delete_min()` methods dereference `min_node` without guarding an empty heap, so traces that call either operation while empty are outside the source's valid behavior; the ABI reports them as invalid with `-1`. Invalid opcodes, nonzero query arguments, malformed input, and out-of-range insert values also return `-1`. Insufficient output capacity returns `-2`.

Successful output is the query result sequence in trace order, encoded as little-endian signed 64-bit integers. The return value is the number of output values written. A trace with no queries returns zero and writes no bytes.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binomial_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/binomial_heap/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binomial_heap.c`](../../../c/b/binomial_heap.c) |
| C3 | [`c3/b/binomial_heap.c3`](../../../c3/b/binomial_heap.c3) |
| C++ | [`cpp/b/binomial_heap.cpp`](../../../cpp/b/binomial_heap.cpp) |
| Elisa | [`elisa/b/binomial_heap.elisa`](../../../elisa/b/binomial_heap.elisa) |
| Nim | [`nim/b/binomial_heap.nim`](../../../nim/b/binomial_heap.nim) |
| Odin | [`odin/b/binomial_heap.odin`](../../../odin/b/binomial_heap.odin) |
| Rust | [`rust/b/binomial_heap.rs`](../../../rust/b/binomial_heap.rs) |
| V | [`v/b/binomial_heap.v`](../../../v/b/binomial_heap.v) |
| Zig | [`zig/b/binomial_heap.zig`](../../../zig/b/binomial_heap.zig) |

## Pinned source

- Python [`binomial_heap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/binomial_heap.py)
