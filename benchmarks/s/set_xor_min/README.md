# Set XOR minimum

Maintain a set of nonnegative 30-bit integers with idempotent insertion and
deletion, and answer minimum-XOR queries. A binary trie stores each integer's
bits from most significant to least significant. Every node tracks the number
of active values below it; a query follows the matching bit when that subtree
is nonempty and otherwise takes the opposite bit.

## Contract

The official operations are `0 x` (insert), `1 x` (remove), and `2 x` (report
`min(y XOR x)` for `y` in the set). Inserting an existing value and deleting an
absent value have no effect. Query operations require a nonempty set. The
official domain is `0 <= x < 2^30`, with up to 500,000 operations.

The bounded ABI encodes `[Q,(type,x)...]`, with `1 <= Q <= 64`. Query values
must be valid for the current set; malformed operations, out-of-range values,
and queries on an empty set return `-1`. Each type-2 answer is written as a
signed 64-bit little-endian integer. A null or undersized output buffer
returns `-2` without writing. The fixed node pool contains at most one root
plus 30 new nodes per insertion operation. The workload's
`workspace.bytes=512` is the maximum output-buffer capacity; trie storage is
described separately.

## Distinctness

The local [`trie`](../../t/trie/README.md) benchmark stores lowercase words and
answers exact-word and prefix operations. Integer XOR helpers implement
bitwise arithmetic or ciphers. None maintains a set of 30-bit integers for
greedy minimum-XOR queries, so this binary-trie workload is a distinct
algorithm.

Official contract: [Library Checker — Set XOR-Min](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/set_xor_min/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/set_xor_min/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers overlapping trie paths, duplicate
insertion, absent deletion, high bits, empty-set queries, malformed values,
and short output capacity. The independent
[`benchmarks/set_xor_min_oracle.py`](../../set_xor_min_oracle.py) uses a Python
set and scans all active values for each query.

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/set_xor_min.c`](../../../c/s/set_xor_min.c) |
| C3 | [`c3/s/set_xor_min.c3`](../../../c3/s/set_xor_min.c3) |
| C++ | [`cpp/s/set_xor_min.cpp`](../../../cpp/s/set_xor_min.cpp) |
| Elisa | [`elisa/s/set_xor_min.elisa`](../../../elisa/s/set_xor_min.elisa) |
| Nim | [`nim/s/set_xor_min.nim`](../../../nim/s/set_xor_min.nim) |
| Odin | [`odin/s/set_xor_min.odin`](../../../odin/s/set_xor_min.odin) |
| Rust | [`rust/s/set_xor_min.rs`](../../../rust/s/set_xor_min.rs) |
| V | [`v/s/set_xor_min.v`](../../../v/s/set_xor_min.v) |
| Zig | [`zig/s/set_xor_min.zig`](../../../zig/s/set_xor_min.zig) |
| Mojo | [`mojo/s/set_xor_min.mojo`](../../../mojo/s/set_xor_min.mojo) |
