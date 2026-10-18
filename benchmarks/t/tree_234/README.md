# 2-3-4 Tree

This benchmark measures the public insertion and removal operations of the pinned 2-3-4 tree and its final in-order traversal. It captures the duplicate-key and missing-key behavior without exposing internal node shape or demo file output.

## Contract

Input is a signed-i64 array:

```text
[operation_count, operation_0, key_0, ..., operation_(n-1), key_(n-1)]
```

There are 0 through 128 operations. Operation `0` inserts a signed-i64 key; operation `1` removes a signed-i64 key. Input length must equal `1 + 2 * operation_count`; at most 257 words are valid, and 258 words are parseable for a trailing-data check.

Insertion ignores duplicate keys. Removal reports 1 if the key existed and was removed, or 0 if it was absent. The final traversal emits each remaining key once in ascending order. The pinned source uses pre-split insertion and pre-merge removal; those choices preserve the public behaviors above.

Output is little-endian signed-i64 words `[remove_count, remove_result_0, ..., final_item_count, sorted_item_0, ...]`. Remove results retain operation order. The maximum is 130 words or 1040 bytes: each remove record consumes one operation and each final key requires at least one insertion operation, so their combined count cannot exceed the 128-operation limit. With zero operations the output is `[0, 0]` (16 bytes). Success returns the output byte count.

Null input, malformed framing, or an unknown operation returns `-1` before output checks. Null output or insufficient byte capacity returns `-2`, including for zero operations. Errors write no bytes.

## Pinned sources

- C++ [`tree_234.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/tree_234.cpp), class `Tree234`, commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- C++ (additional repository) [`tree_234.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/tree_234.cpp), class `Tree234`, commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

The two pinned sources have the same public insert, remove, and traverse behavior; their visible difference is in a demo comment.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/tree_234_oracle.py`](../../tree_234_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/t/tree_234.c`](../../../c/t/tree_234.c) |
| C3 | [`c3/t/tree_234.c3`](../../../c3/t/tree_234.c3) |
| C++ | [`cpp/t/tree_234.cpp`](../../../cpp/t/tree_234.cpp) |
| Elisa | [`elisa/t/tree_234.elisa`](../../../elisa/t/tree_234.elisa) |
| Nim | [`nim/t/tree_234.nim`](../../../nim/t/tree_234.nim) |
| Odin | [`odin/t/tree_234.odin`](../../../odin/t/tree_234.odin) |
| Rust | [`rust/t/tree_234.rs`](../../../rust/t/tree_234.rs) |
| V | [`v/t/tree_234.v`](../../../v/t/tree_234.v) |
| Zig | [`zig/t/tree_234.zig`](../../../zig/t/tree_234.zig) |
