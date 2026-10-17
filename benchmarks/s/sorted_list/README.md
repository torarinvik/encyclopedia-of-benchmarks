# Sorted-list operation trace

This benchmark follows the pinned C# array-backed sorted collection for
nonnegative integer keys. It applies a deterministic operation trace and
returns a checksum of query results and the final sorted contents.

## Contract

The `i64_array_scalar` input is a sequence of `[opcode, payload]` pairs, with
at most 512 operations. Opcodes are:

- `0`: add `payload`, an integer from 0 through 1,000,000
- `1`: report whether `payload` is present
- `2`: try to remove one occurrence of `payload`, reporting success
- `3`: report the collection count; `payload` must be zero
- `4`: return the element at sorted zero-based index `payload`
- `5`: clear the collection; `payload` must be zero

The collection starts empty. It remains sorted in ascending order and permits
duplicates. Its size is bounded to 256 items for this benchmark. An index
query must refer to an existing item. Odd-length input, more than 512
operations, an unknown opcode, an invalid payload, an out-of-range index, or
an operation that would exceed 256 items returns `-1`. Empty input is a
valid zero-operation trace. The maximum valid input length is 1,024 integers;
up to 1,025 integers may be parsed so an odd-length frame can be rejected.

For each `Contains`, `TryRemove`, `Count`, or index operation, let `observed`
be its Boolean result represented as 0 or 1, the count, or the returned item.
The operation contributes
`(one_based_operation_index) * (observed + 1,000,000)` to the checksum. After
the trace, each remaining sorted value contributes
`(operation_count + one_based_sorted_position) * (value + 1,000,000)`. Add
and Clear have no operation result. The empty trace returns zero; all valid
results are nonnegative and fit in signed 64-bit.

The source stores values in a `List<T>`. Its binary search returns an equal
midpoint immediately, so Add may insert a duplicate next to any equal item
found by that search; `TryRemove` deletes one equal item. The contract uses
integer keys, so equal items have no observable identity. The source indexer
throws for an invalid index; this benchmark treats such a trace as invalid.
The benchmark's 256-item and 512-operation bounds keep traces and checksums
within the portable ABI.

## Pinned source

- TheAlgorithms/C-Sharp [`DataStructures/SortedList.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SortedList.cs), commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`

## Workload

The workload is [`workload.json`](workload.json); the independent sorted-list
trace oracle is [`benchmarks/sorted_list_oracle.py`](../../sorted_list_oracle.py).

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/sorted_list.c`](../../../c/s/sorted_list.c) |
| C3 | [`c3/s/sorted_list.c3`](../../../c3/s/sorted_list.c3) |
| C++ | [`cpp/s/sorted_list.cpp`](../../../cpp/s/sorted_list.cpp) |
| Elisa | [`elisa/s/sorted_list.elisa`](../../../elisa/s/sorted_list.elisa) |
| Nim | [`nim/s/sorted_list.nim`](../../../nim/s/sorted_list.nim) |
| Odin | [`odin/s/sorted_list.odin`](../../../odin/s/sorted_list.odin) |
| Rust | [`rust/s/sorted_list.rs`](../../../rust/s/sorted_list.rs) |
| V | [`v/s/sorted_list.v`](../../../v/s/sorted_list.v) |
| Zig | [`zig/s/sorted_list.zig`](../../../zig/s/sorted_list.zig) |
