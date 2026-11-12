# Bounded hash join

This package benchmarks the hash-join operation over two small relations of
signed integer keys. It uses the Rosetta Code task as a discovery source and
implements the operation from its high-level algorithm description.

## Contract

The exported symbol is `hash_join(input, length, output, capacity) -> i64` in
the `i64_array_bytes_output` ABI. Input is
`[left_count,right_count,left_keys...,right_keys...]`; each relation has 0 to 8
rows, keys are any signed i64, and the frame length must be exactly
`2+left_count+right_count`. The maximum valid frame has 18 values; a 19-value
frame is parseable but malformed when it contains a trailing value.

The implementation hashes the smaller relation into a 17-slot open-addressed
table using the key's normalized remainder modulo 17 and linear probing. Equal
keys share a bucket record whose posting chain retains every row ID in input
order. Ties choose the right relation as the build side. The other
relation is scanned in input order; matching build rows are visited in their
input order. Each output byte packs `(left_row_id << 4) | right_row_id`, so the
high nibble is always the left ID and the low nibble the right ID, even when
the left side is built. At most 64 matches fit in the maximum 64-byte output.
The function returns the match count. Malformed frames return `-1`; null output
or capacity below the actual result size returns `-2` without writes. A valid
empty join returns zero bytes when given a non-null output buffer.

Primary time is expected `O(L+R+K)` for `L` left rows, `R` right rows, and `K`
matches. With adversarial hash collisions, bounded worst-case time is
`O(B²+P·U+K)`, where `B` is the build size, `P` is the probe size, and `U` is
the number of distinct build keys. Auxiliary storage is `O(17+B+K)`. The
independent nested-loop oracle takes `O(L·R)` time.

The local [`join`](../../j/join/README.md) benchmark concatenates strings, and the
hash-map packages measure container operations. Neither implements relational
inner join. The primary oracle uses the hash table and duplicate posting
chains; the independent oracle checks every left/right pair directly.

The [workload](workload.json) covers duplicate keys, unmatched rows, modulo
hash collisions, both build-side choices, empty relations, maximum output,
malformed framing, null pointers, and output capacity. The package-local
[`check_inventory.py`](check_inventory.py) reviews paths and metadata without
compiling the ports.

## Provenance and rights

The task was found in the [RosettaGit Hash join index](https://rosettagit.org/tasks/hash-join/),
which describes building a key-to-rows multimap for one relation and probing
it with the other. The task page is licensed GFDL-1.3-or-later. This package
uses only the algorithm idea and title for discovery; its contract, workload,
oracles, and implementations are original.

See [`RIGHTS.md`](RIGHTS.md) for the clean-room note.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hash_join.c`](../../../c/h/hash_join.c) |
| C3 | [`c3/h/hash_join.c3`](../../../c3/h/hash_join.c3) |
| C++ | [`cpp/h/hash_join.cpp`](../../../cpp/h/hash_join.cpp) |
| Elisa | [`elisa/h/hash_join.elisa`](../../../elisa/h/hash_join.elisa) |
| Mojo | [`mojo/h/hash_join.mojo`](../../../mojo/h/hash_join.mojo) |
| Nim | [`nim/h/hash_join.nim`](../../../nim/h/hash_join.nim) |
| Odin | [`odin/h/hash_join.odin`](../../../odin/h/hash_join.odin) |
| Rust | [`rust/h/hash_join.rs`](../../../rust/h/hash_join.rs) |
| V | [`v/h/hash_join.v`](../../../v/h/hash_join.v) |
| Zig | [`zig/h/hash_join.zig`](../../../zig/h/hash_join.zig) |
