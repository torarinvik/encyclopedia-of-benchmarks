# Randomized heap operation trace

This benchmark follows the pinned Python meldable min-heap. Its recursive merge randomly swaps child links, so tree shape can vary, while the minimum key returned by `top` and `pop` remains ordered. The ABI exposes insert, top, pop, and `isEmpty`; ports do not need to reproduce internal randomized shape, so deterministic heap implementations are valid when they preserve these observable results.

## Contract

- The ABI is `i64_array_bytes_output`. Input is `[operation_count, opcode, key_if_insert, ...]`, with 0–64 exact operations. Opcode `0` inserts a signed-i32 key, `1` returns the minimum without removing it, `2` removes and returns the minimum, and `3` reports whether the heap is empty. Only insert consumes a key. Duplicate keys are valid.
- Top and pop on an empty heap make the trace invalid and return `-1`, matching the pinned source's `IndexError`. `isEmpty` is valid for either heap state. Invalid or null input returns `-1` before output-buffer checks.
- Insert emits no result. Each top, pop, or `isEmpty` emits `[kind, value]`: kind `1` for top, `2` for pop, and `3` for `isEmpty` (value `1` if empty, otherwise `0`). Output is `[query_count, kind, value, ...]` in little-endian signed-i32 words. The empty trace `[0]` returns `[0]` in 4 bytes.
- The maximum input is 129 signed-i64 words for 64 inserts. A valid trace may contain 64 `isEmpty` queries without inserting, so the maximum output and workspace are 516 bytes. A null output pointer or insufficient capacity returns `-2` without writes.
- The source's `clear` and `to_sorted_list` methods are excluded. `to_sorted_list` drains the heap by repeatedly popping values.

The workload and ABI cases are in [workload.json](workload.json). The independent min-heap oracle is [benchmarks/randomized_heap_oracle.py](../../randomized_heap_oracle.py).

Pinned source: [TheAlgorithms/Python `randomized_heap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/randomized_heap.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm randomized_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm randomized_heap
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm randomized_heap --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/randomized_heap.c](../../../c/r/randomized_heap.c) |
| C3 | [c3/r/randomized_heap.c3](../../../c3/r/randomized_heap.c3) |
| C++ | [cpp/r/randomized_heap.cpp](../../../cpp/r/randomized_heap.cpp) |
| Elisa | [elisa/r/randomized_heap.elisa](../../../elisa/r/randomized_heap.elisa) |
| Nim | [nim/r/randomized_heap.nim](../../../nim/r/randomized_heap.nim) |
| Odin | [odin/r/randomized_heap.odin](../../../odin/r/randomized_heap.odin) |
| Rust | [rust/r/randomized_heap.rs](../../../rust/r/randomized_heap.rs) |
| V | [v/r/randomized_heap.v](../../../v/r/randomized_heap.v) |
| Zig | [zig/r/randomized_heap.zig](../../../zig/r/randomized_heap.zig) |
