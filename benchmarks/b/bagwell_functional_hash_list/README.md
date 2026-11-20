# Bagwell functional hash-list

This profile measures the block-local hash-list described by Bagwell. A
front-cons trace appends key/value entries to geometrically growing blocks of
side 8, 16, and 32. Each saved root is the block and local offset visible at
that insertion count. A lookup searches the root's bucket chain, ignores newer
entries in that block, and follows explicit previous-block links when it must
continue its search.

## Trace contract

The `i64_array_bytes_output` input is
`[n,(key,value)*n,q,(root,key)*q]`, with `0<=n<=32` and `1<=q<=32`. Keys and
values are signed 32-bit integers carried in i64 words. Root `r` observes the
first `r` front-cons entries; duplicate keys resolve to the newest visible
entry. Missing keys return `INT64_MIN`. The output is exactly `q` little-endian
i64 values, so it is at most 256 bytes. Invalid input returns `-1`; a null or
undersized output buffer returns `-2` after input validation.

The maximum valid frame has 130 words; 131 words is the parseable bound. Fixed
workspace is capped at 4,096 bytes. Each block has its own low-bit bucket table
and offset chains; because block sides are powers of two, selecting a bucket
with the low bits agrees with Euclidean `key mod side`, including negative
keys. At most 32 insertions and 32 queries are processed.

The primary reference stores block bucket heads, chain offsets, previous-block
links, and root `(block,offset)` pairs. The independent reference scans the
visible prefix newest-first. Fixtures cover duplicate shadowing, snapshot
visibility, both block transitions, full frame/output bounds, malformed
inputs, and output-capacity behavior.

| Language | Port |
|---|---|
| C | [c/b/bagwell_functional_hash_list.c](../../../c/b/bagwell_functional_hash_list.c) |
| C3 | [c3/b/bagwell_functional_hash_list.c3](../../../c3/b/bagwell_functional_hash_list.c3) |
| C++ | [cpp/b/bagwell_functional_hash_list.cpp](../../../cpp/b/bagwell_functional_hash_list.cpp) |
| Elisa | [elisa/b/bagwell_functional_hash_list.elisa](../../../elisa/b/bagwell_functional_hash_list.elisa) |
| Mojo | [mojo/b/bagwell_functional_hash_list.mojo](../../../mojo/b/bagwell_functional_hash_list.mojo) |
| Nim | [nim/b/bagwell_functional_hash_list.nim](../../../nim/b/bagwell_functional_hash_list.nim) |
| Odin | [odin/b/bagwell_functional_hash_list.odin](../../../odin/b/bagwell_functional_hash_list.odin) |
| Rust | [rust/b/bagwell_functional_hash_list.rs](../../../rust/b/bagwell_functional_hash_list.rs) |
| V | [v/b/bagwell_functional_hash_list.v](../../../v/b/bagwell_functional_hash_list.v) |
| Zig | [zig/b/bagwell_functional_hash_list.zig](../../../zig/b/bagwell_functional_hash_list.zig) |

The profile is based on the algorithmic description in Phil Bagwell,
[*Fast Functional Lists, Hash-Lists, Deques and Variable Length Arrays*],
§3 and Fig. 6. The source code and fixtures here are independently authored.

[*Fast Functional Lists, Hash-Lists, Deques and Variable Length Arrays*]: https://lampwww.epfl.ch/papers/techlists.pdf
