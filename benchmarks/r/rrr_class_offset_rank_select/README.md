# RRR-style class/offset rank and select

This draft encodes each 8-bit block by its class (number of one bits) and its
zero-based offset among same-class byte patterns in increasing numeric order.
Queries decode a block from its class and offset and use prefix class totals.
The existing [`rank_select_bitstring`](../rank_select_bitstring/README.md)
stores and scans plain blocks rather than encoding and decoding them.

Input is `[bit_length, packed_bits, query_count, (opcode,index)*]`, with
`1<=bit_length<=63`, bits above the declared length zero, and `0<=query_count<=16`.
The least-significant bit is position 1. Opcode 0 returns the number of set
bits in positions 1 through `index`, where `1<=index<=bit_length`. Opcode 1
returns the position of the `index`th one, or -1 if absent, where
`1<=index<=64`. Every answer is a little-endian signed i64; return the number
of bytes written. Invalid input or null input returns -1. Valid input with a
null output or capacity below `8*query_count` returns -2 without writing,
including a null output for zero queries. This matches the existing rank/select
package's input and output semantics.

The final partial block is zero-padded before encoding. Encoding and decoding
enumerate at most 256 patterns per block; prefix counts allow selecting a block
before decoding it. Fixed arrays store one class and offset per block, rather
than packed entropy-sized fields, so this bounded profile does not claim the
full RRR succinct-space or constant-time bounds. Its worst-case work is
`O((n/8+q)*256*8)` and space is `O(n/8+q)` for bit length n and q queries.

The class/offset idea is from Raman, Raman, and Rao's [*Succinct Indexable
Dictionaries*](https://arxiv.org/abs/0705.0552). Only the algorithmic idea and
bibliographic facts are used. Ten language drafts, two references, workload,
inventory checker, and byte-output runner/verifier integration are present.
Verifier source specifies every byte pattern, partial blocks, boundary queries,
short buffers, and null pointers. The Elisa draft uses bounded views and indexed
arrays. Nothing has been compiled or run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/r/rrr_class_offset_rank_select.c) |
| C3 | [C3](../../../c3/r/rrr_class_offset_rank_select.c3) |
| C++ | [C++](../../../cpp/r/rrr_class_offset_rank_select.cpp) |
| Elisa | [Elisa](../../../elisa/r/rrr_class_offset_rank_select.elisa) |
| Mojo | [Mojo](../../../mojo/r/rrr_class_offset_rank_select.mojo) |
| Nim | [Nim](../../../nim/r/rrr_class_offset_rank_select.nim) |
| Odin | [Odin](../../../odin/r/rrr_class_offset_rank_select.odin) |
| Rust | [Rust](../../../rust/r/rrr_class_offset_rank_select.rs) |
| V | [V](../../../v/r/rrr_class_offset_rank_select.v) |
| Zig | [Zig](../../../zig/r/rrr_class_offset_rank_select.zig) |
