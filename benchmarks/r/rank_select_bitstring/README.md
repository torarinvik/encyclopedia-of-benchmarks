# Rank and select on bit strings

This profile supports the chapter's one-based `rank₁(i)` and `select₁(k)`
operations on a static bit string. `rank₁(i)` counts 1 bits in positions 1
through `i`; `select₁(k)` returns the position of the k-th 1, or `-1` when
`k` exceeds the number of 1s. The bit string is packed into one signed
64-bit value, with its least-significant bit representing position 1.

Input is `[bit_length, packed_bits, query_count, (opcode,index)*]`, where
`1 <= bit_length <= 63`, at most 16 queries are supplied, opcode 0 means
`rank₁`, and opcode 1 means `select₁`. Output contains one little-endian
signed 64-bit answer per query. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing. With zero queries, a
non-null output and zero capacity succeed with an empty result.

Rank indexes are limited to `1..bit_length`; select indexes are limited to
`1..64`, so absent selections beyond the maximum 63 one bits return `-1`.

The ports build an 8-bit block prefix-rank index. Rank uses the stored count
before its block and scans the remaining bits in that block; select locates
the block from its prefix counts and scans within it. This deterministic
bounded index is a concrete profile of the chapter's bit-vector rank/select
problem. It is separate from the value-partitioned [wavelet tree](../wavelet_tree/README.md),
which answers rank over arbitrary values and does not expose bitvector
`select₁`.

Source: “Rank and Select Operations on Bit Strings,” Rajeev Raman,
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_332`](https://doi.org/10.1007/978-1-4939-2864-4_332).
The chapter is used only for the rank/select definitions and bit-vector
problem; this is clean-room code with no copied book prose, figures, or code.

Primary oracle: [`rank_select_bitstring_oracle.py`](../../rank_select_bitstring_oracle.py).
Independent verifier: [`rank_select_bitstring_verifier_oracle.py`](../../rank_select_bitstring_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/r/rank_select_bitstring.c` |
| C3 | `c3/r/rank_select_bitstring.c3` |
| C++ | `cpp/r/rank_select_bitstring.cpp` |
| Elisa | `elisa/r/rank_select_bitstring.elisa` |
| Nim | `nim/r/rank_select_bitstring.nim` |
| Odin | `odin/r/rank_select_bitstring.odin` |
| Rust | `rust/r/rank_select_bitstring.rs` |
| V | `v/r/rank_select_bitstring.v` |
| Zig | `zig/r/rank_select_bitstring.zig` |
