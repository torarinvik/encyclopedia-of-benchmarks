# Sorted-table operation trace

This benchmark follows the pinned Lua sorted table and its sorted-set API for
integer keys. The table stores keys in ascending order under the strict
comparator `a < b`; its initial key array must already be strictly increasing
and unique. Inserts preserve uniqueness, and lookups, neighbor queries, and
inclusive range iterators retain the source's semantics.

## Contract

The `i64_array_scalar` input is
`[initial_count, initial_keys..., operation_count, opcode, a, b, ...]`.
There are at most 128 initial keys and 256 operations; the final set may hold
at most 256 keys. Keys and range endpoints are signed integers in
`-1,000,000..1,000,000`. Initial keys must be strictly increasing. Each
operation occupies three integers:

- `0`: `find(a)`; `b` must be zero
- `1`: `has(a)`; `b` must be zero
- `2`: `min()`; both arguments must be zero
- `3`: `max()`; both arguments must be zero
- `4`: `succ(a)`; `b` must be zero
- `5`: `pred(a)`; `b` must be zero
- `6`: `insert(a, upsert)`; `b` is 0 or 1
- `7`: `remove(a)`; `b` must be zero
- `8`: iterate `range_ascending(a, b)`
- `9`: iterate `range_descending(a, b)`
- `10`: iterate all keys ascending; both arguments must be zero
- `11`: iterate all keys descending; both arguments must be zero
- `12`: `empty()`; both arguments must be zero
- `13`: `clear()`; both arguments must be zero

Key-returning operations contribute their key when present and zero when the
source returns `nil`. A present key is encoded as
`key - (-1,000,000) + 1`, so key zero remains distinct from `nil`. Boolean
results are encoded as 0 or 1. Range and full-iteration results are encoded
as `length * 1,000,000,007 + h`, where `h` starts at zero and folds each key
in yielded order with `h = (31 * h + encoded_key) mod 1,000,000,007`. Thus
ascending and descending results remain distinguishable. Each operation with
a result contributes `(one_based_operation_index) * (encoded_result + 1)`.
After all operations, each final key contributes
`(operation_count + one_based_sorted_position) * encoded_key`. Insert,
remove, min, max, find, successor, and predecessor use the value returned by
the source; Clear has no operation result. The empty set with no operations
returns zero. Valid checksums are nonnegative and fit signed 64-bit.

The source's range methods use Lua truthiness to decide whether a bound is
present. This contract supplies both numeric range bounds, which are always
non-false in Lua (including zero), and does not encode unbounded range calls.
Range endpoints are inclusive: the first key is the first value greater than
or equal to `a`, and the last is the last value less than or equal to `b`.
If `a > b`, the iterator is empty. `succ` is strictly greater than its
argument and `pred` is strictly less. `insert` returns the existing key; flag
0 leaves it unchanged and flag 1 requests upsert. The benchmark maps the
integer flag explicitly to false/true because Lua treats numeric zero as
truthy. Initial keys are constrained to the constructor's documented sorted,
unique invariant; the source does not validate that invariant itself.
The representation is an array-backed Lua table: binary-search queries take
O(log n), while inserts and removals shift keys and take O(n).

Odd framing, invalid counts or keys, a non-strict initial order, unknown
opcodes, invalid operation arguments, more than 256 final keys, or an input
longer than 899 integers returns `-1`. The maximum valid input has 898
integers; up to 899 are parsed so an extra value can be rejected.

## Pinned sources

- TheAlgorithms/Lua [`sorted_table.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/sorted_table.lua), commit `cedc141018ad48884318fe08a6db278664b17128`
- Its sorted-set base class [`sorted_set.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/sorted_set/sorted_set.lua) and comparator-based [`binary_search.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/searches/binary_search.lua), at the same commit

## Workload

The workload is [`workload.json`](workload.json); the independent linear
sorted-set trace oracle is [`benchmarks/sorted_table_oracle.py`](../../sorted_table_oracle.py).

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/sorted_table.c`](../../../c/s/sorted_table.c) |
| C3 | [`c3/s/sorted_table.c3`](../../../c3/s/sorted_table.c3) |
| C++ | [`cpp/s/sorted_table.cpp`](../../../cpp/s/sorted_table.cpp) |
| Elisa | [`elisa/s/sorted_table.elisa`](../../../elisa/s/sorted_table.elisa) |
| Nim | [`nim/s/sorted_table.nim`](../../../nim/s/sorted_table.nim) |
| Odin | [`odin/s/sorted_table.odin`](../../../odin/s/sorted_table.odin) |
| Rust | [`rust/s/sorted_table.rs`](../../../rust/s/sorted_table.rs) |
| V | [`v/s/sorted_table.v`](../../../v/s/sorted_table.v) |
| Zig | [`zig/s/sorted_table.zig`](../../../zig/s/sorted_table.zig) |
