# Lua median heap trace

This benchmark ports the pinned Lua `median_heap` structure and its binary-heap
helper. Each call starts with an empty structure and replays a bounded sequence
of method calls.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[operation_count, (opcode, argument)*]`, with 0 through 256 operations and
  exactly `1 + 2 * operation_count` signed-i64 words. The maximum valid input
  has 513 words; 514 are parseable so a trailing word can be rejected.
- Opcode `0` calls `push(value)`, where `value` is signed i32. At most 64 values
  may be live. Opcode `1` calls `top()`, `2` calls `pop()`, `3` calls `size()`,
  and `4` calls `empty()`. The argument word must be zero for opcodes 1 through
  4. Push at capacity, invalid opcodes, invalid padding, and values outside
  signed i32 invalidate the trace.
- The adapter explicitly supplies the source's `median_heap.less_than`
  comparator (`a < b`) to `median_heap.new(less_than)`. The structure keeps a
  max-heap of the lower half and a min-heap of the upper half. Push routing and
  both rebalancing directions follow the source. `top()` returns the lower
  heap's root, the sorted lower median at index `(size - 1) // 2`; `pop()` returns
  and removes that same value, then moves one upper root to the lower heap only
  if the lower heap became smaller. This is the lower median for even sizes.
- Every operation emits one little-endian signed-i64 result. `push()` returns
  Lua `nil`; `top()` and `pop()` also return `nil` when empty. The adapter
  serializes each of those nil results as `INT64_MIN` (`-9223372036854775808`),
  which cannot collide with accepted signed-i32 pushed values. `size()` emits
  the live count and `empty()` emits 1 for true or 0 for false. Empty `top()`
  and `pop()` are valid source operations and produce the nil sentinel.
- Output is at most 256 words / 2,048 bytes. The result is the number of
  output bytes. Null or invalid input returns `-1` before output checks.
  Invalid traces produce no partial output. Null output or capacity below the
  required byte count returns `-2`; a nonnull zero-capacity buffer succeeds
  for a zero-operation trace and returns 0.

The pinned Lua class is
[`median_heap.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/median_heap.lua),
and its heap dependency is
[`heap.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/heap.lua).
Both are pinned at commit `cedc141018ad48884318fe08a6db278664b17128`.

See [workload.json](workload.json) and the independent
[sorted-list oracle](../../median_heap_oracle.py).

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm median_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm median_heap
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm median_heap --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/median_heap.c](../../../c/m/median_heap.c) |
| C3 | [c3/m/median_heap.c3](../../../c3/m/median_heap.c3) |
| C++ | [cpp/m/median_heap.cpp](../../../cpp/m/median_heap.cpp) |
| Elisa | [elisa/m/median_heap.elisa](../../../elisa/m/median_heap.elisa) |
| Nim | [nim/m/median_heap.nim](../../../nim/m/median_heap.nim) |
| Odin | [odin/m/median_heap.odin](../../../odin/m/median_heap.odin) |
| Rust | [rust/m/median_heap.rs](../../../rust/m/median_heap.rs) |
| V | [v/m/median_heap.v](../../../v/m/median_heap.v) |
| Zig | [zig/m/median_heap.zig](../../../zig/m/median_heap.zig) |
