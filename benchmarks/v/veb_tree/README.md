# Van Emde Boas Tree

This benchmark adapts the pinned Rust Van Emde Boas set. It preserves set insertion, membership, strict successor and predecessor, and minimum and maximum queries. The source has no delete operation. A bounded requested universe keeps every implementation's storage predictable; the source rounds that universe up internally.

## Contract

The `i64_array_bytes_output` input is a signed 64-bit array:

    [U, insert_count, query_count, inserted_value..., (opcode, key)...]

`U` is from 2 through 256. The source rounds it up to the next power of two internally; every inserted value and every encoded key is still restricted to `[0,U)`. Both counts are from 0 through 256. The input length must be exactly `3 + insert_count + 2 * query_count`. Duplicate insertions are idempotent.

Opcodes are `0` contains, `1` strict successor, `2` strict predecessor, `3` minimum, and `4` maximum. Contains emits 0 or 1. Successor and predecessor emit the matching value or `u32::MAX` when none exists. Minimum emits `u32::MAX` for an empty tree, while maximum emits 0. Their key field is validated like every other key and otherwise ignored. These raw sentinels are written as four little-endian bytes, so `u32::MAX` is `FF FF FF FF`.

Each query emits one raw little-endian 32-bit word. The result is the number of output bytes written: `4 * query_count`, at most 1,024 bytes. Malformed input returns -1 before output checks. For otherwise-valid input, null output or insufficient capacity returns -2 without writes, including a null output for zero queries. A nonnull output with zero capacity succeeds when there are no queries.

Each language port uses the Van Emde Boas set recurrence: a non-base node stores its minimum and maximum outside its recursively allocated summary and clusters, and successor/predecessor consult a local cluster before the summary. The ports use a canonical power-of-two low/high split after rounding the requested universe. The pinned Rust source chooses its child size with a ceiling-square-root rule, so its internal layout differs while the bounded set/query results remain the same. Keys are restricted to the originally requested universe.

## Workload and oracle

The workload covers empty queries, duplicate insertion, strict boundary queries, all operation kinds, a non-power-of-two requested universe, capacity failures, malformed frames, and the maximum input/output size. The independent reference implementation is `benchmarks/veb_tree_oracle.py`.

Build an implementation and its ABI checker with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm veb_tree --language rust --with-checker

## Implementations

| Language | Source |
| --- | --- |
| C | `c/v/veb_tree.c` |
| C3 | `c3/v/veb_tree.c3` |
| C++ | `cpp/v/veb_tree.cpp` |
| Elisa | `elisa/v/veb_tree.elisa` |
| Nim | `nim/v/veb_tree.nim` |
| Odin | `odin/v/veb_tree.odin` |
| Rust | `rust/v/veb_tree.rs` |
| V | `v/v/veb_tree.v` |
| Zig | `zig/v/veb_tree.zig` |

## Reviewed source

The source is `veb_tree.rs` in TheAlgorithms/Rust at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. Its constructor rounds the requested size up to a power of two and chooses child universes with a ceiling-square-root rule. The adapter preserves the source's raw empty min/max sentinels and restricts keys to the requested universe.
