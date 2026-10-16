# Generic Heap

This benchmark is based on the pinned Python Heap class with its default identity key, which creates a max heap of item priorities. Items have stable integer IDs so the index map, priority update, and arbitrary deletion are observable.

## Contract

- Input is a signed 64-bit array packed as [operation_count, (opcode, item_id, priority)*], with at most 512 operations and 128 live items.
- IDs are 0 through 4095 and may be inserted at most once in a trace. Priorities are signed 32-bit values and must be distinct among live items. These bounds avoid duplicate-ID map corruption and comparator-tie ambiguity in the source.
- Opcode 0 inserts a new ID with a priority. Opcode 1 observes the maximum item. Opcode 2 removes and returns the maximum item. Opcode 3 updates a live item's priority and runs the source's upward repair followed by its downward repair at the original index. Opcode 4 deletes a live item by ID.
- Peek and extract require zero in their unused ID and priority fields. Delete requires zero in its unused priority field. Empty peek or extract returns no item. Updates and deletes must refer to a live ID.
- Each operation contributes an output record to FNV-1a-64: opcode as one byte, presence as one byte, then (when present) the returned item ID as signed i32 little-endian and its priority as signed i32 little-endian. Insert, update, delete, empty peek, and empty extract have no returned item.
- The final unsigned FNV-1a-64 bits are interpreted as signed i64. Malformed traces return -1; an empty trace returns the offset basis interpreted as signed i64.

## Workload and implementation

The workload covers empty results, maximum lookup and removal, priority increases and decreases, arbitrary deletion, ID reuse, duplicate priorities, and malformed records. All nine ports use the i64-array scalar ABI.

The ports maintain a max heap, an ID-to-index map, and a set of IDs already used in the trace. The upward-then-downward update and deletion repairs preserve the pinned source's operation order.

## Upstream source

[Python heap_generic.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/heap_generic.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/heap_generic.c](../../../c/h/heap_generic.c) |
| C3 | [c3/h/heap_generic.c3](../../../c3/h/heap_generic.c3) |
| C++ | [cpp/h/heap_generic.cpp](../../../cpp/h/heap_generic.cpp) |
| Elisa | [elisa/h/heap_generic.elisa](../../../elisa/h/heap_generic.elisa) |
| Nim | [nim/h/heap_generic.nim](../../../nim/h/heap_generic.nim) |
| Odin | [odin/h/heap_generic.odin](../../../odin/h/heap_generic.odin) |
| Rust | [rust/h/heap_generic.rs](../../../rust/h/heap_generic.rs) |
| V | [v/h/heap_generic.v](../../../v/h/heap_generic.v) |
| Zig | [zig/h/heap_generic.zig](../../../zig/h/heap_generic.zig) |
