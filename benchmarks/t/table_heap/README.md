# Lua table-backed min-heap

This benchmark replays bounded operations on the pinned Lua table-backed min-heap. The source keeps heap elements as unique signed 32-bit IDs, a separate priority map through its `less_than(id_a, id_b)` comparator, and an ID-to-current-heap-index map. Ports must maintain that index map across heap swaps, pushes, pops, replacements, and removals, and use direct map lookups for `find_index` and ID-based mutations rather than scanning the heap.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[initial_count, (id, priority)*, operation_count, (opcode, arg1, arg2, arg3)*]`. There are 0–64 initial entries and 0–256 operations. Each live ID is unique; IDs and priorities are signed 32-bit integers. Every operation occupies exactly four words, with unused arguments set to zero. The input length must be exactly `2 + 2 * initial_count + 4 * operation_count`; the maximum valid input is 1,154 words, and one additional parseable word is reserved to reject trailing data (maximum parseable length 1,155).

The comparator is strict `priority[id_a] < priority[id_b]`. Initial entries are heapified bottom-up before the ID-to-index map is built. The map is updated whenever heap elements move, so `find_index` returns the mapped one-based position. For down-heap, the source starts with the right child, selects the left child only when its priority is strictly smaller, and swaps only when the chosen child is strictly smaller than its parent. Equal priorities therefore retain the source's array-heap tie behavior and exposed positions.

Operation codes are:

| Code | Operation | Arguments |
|---:|---|---|
| 0 | `push(id, priority)` | `arg1=id`, `arg2=priority`, `arg3=0` |
| 1 | `top()` | all zero padding |
| 2 | `pop()` | all zero padding |
| 3 | `size()` | all zero padding |
| 4 | `empty()` | all zero padding |
| 5 | `find_index(id)` | `arg1=id`, remaining arguments zero |
| 6 | `decrease(id, new_priority)` | `arg1=id`, `arg2=new_priority`, `arg3=0` |
| 7 | `increase(id, new_priority)` | `arg1=id`, `arg2=new_priority`, `arg3=0` |
| 8 | `replace(old_id, new_id, new_priority)` | all three arguments used |
| 9 | `remove(id)` | `arg1=id`, remaining arguments zero |

For decrease/increase, update the external priority map before calling the matching heapify method; require the new priority to be no greater/no smaller than the old value, respectively. Equal priority is a no-op. Replace requires an existing old ID and either a different, absent new ID or the same ID with unchanged priority (a no-op). Remove and replace retain the old priority until the source comparator has completed its up/down decision. Push at 64 live entries, duplicate live IDs, missing IDs for mutators, and failed assertions are invalid traces. `find_index` on a missing ID and `top` on an empty heap return nil; `pop` on an empty heap is invalid.

Each operation emits one little-endian signed-i64 result: push/decrease/increase/replace/remove and nil results use `INT64_MIN`; top/pop return the ID; find returns a one-based index; size returns the live count; empty returns 1 or 0. The sentinel cannot collide with IDs because IDs are signed i32. A valid trace returns `8 * operation_count` bytes, up to 2,048. Invalid input returns `-1` before output checks. A null output pointer or capacity below the result size returns `-2` without writes.

See [workload.json](workload.json) and the independent [oracle](../../table_heap_oracle.py). The benchmark pins [table_heap.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/table_heap.lua) and its base [heap.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/heap.lua), both at commit `cedc141018ad48884318fe08a6db278664b17128`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm table_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm table_heap
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm table_heap --languages rust
~~~

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/table_heap.c`](../../../c/t/table_heap.c) |
| C3 | [`c3/t/table_heap.c3`](../../../c3/t/table_heap.c3) |
| C++ | [`cpp/t/table_heap.cpp`](../../../cpp/t/table_heap.cpp) |
| Elisa | [`elisa/t/table_heap.elisa`](../../../elisa/t/table_heap.elisa) |
| Odin | [`odin/t/table_heap.odin`](../../../odin/t/table_heap.odin) |
| Nim | [`nim/t/table_heap.nim`](../../../nim/t/table_heap.nim) |
| Rust | [`rust/t/table_heap.rs`](../../../rust/t/table_heap.rs) |
| V | [`v/t/table_heap.v`](../../../v/t/table_heap.v) |
| Zig | [`zig/t/table_heap.zig`](../../../zig/t/table_heap.zig) |
