# Shortcut index for permutation inverse queries

This clean-room profile implements the chapter's shortcut index for a
permutation and its inverse. Each cycle is traversed from its smallest
element; when its length is at least the stride `t`, positions `0,t,2t,...`
receive pointers `t` cycle steps backward. A bit vector marks those positions,
and an ordered pointer array is addressed by the marked bit's rank.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[n, t, permutation_1_to_n..., query_count, (operation, index)*]`.
- `1 <= n <= 16`, `1 <= t <= 16`, and `0 <= query_count <= 16`. The
  permutation must contain every value in `1..n` exactly once. Query
  operation `0` returns `π(index)`; operation `1` returns `π⁻¹(index)`.
  Query indices are one-based and in `1..n`.
- Inverse queries scan forward in the cycle to a marked position, use rank on
  the shortcut bit vector to retrieve its `t`-step back pointer, then follow
  the permutation forward until reaching the queried value and return the
  preceding value. A cycle shorter than `t` has no shortcut and is traversed
  directly. This bounded profile uses direct bitmap rank; it does not claim
  the succinct `o(n)` rank index of the asymptotic construction.
- Output is one little-endian signed 64-bit result per query. A zero-query
  input succeeds with an empty output. Invalid input returns `-1`; a null or
  undersized output returns `-2` without writes. Maximum valid input is 51
  words (52 words are accepted for trailing-data rejection); maximum output
  is 128 bytes.

The primary oracle builds the cycle shortcuts and uses bitmap rank to resolve
inverse queries. The independent verifier obtains inverse values directly
from a separately constructed predecessor table.

## Source and implementation

Based on J. Ian Munro, Venkatesh Raman, Rajeev Raman, and S. Srinivasa Rao,
“Succinct and Compressed Data Structures for Permutations and Integer
Functions,” *Encyclopedia of Algorithms* (2016), DOI
[10.1007/978-1-4939-2864-4_411](https://doi.org/10.1007/978-1-4939-2864-4_411),
Theorem 1's shortcut index. The implementation is clean-room and contains no
copied book prose, figures, or code. See [RIGHTS.md](RIGHTS.md).

Primary oracle: [`permutation_shortcut_index_oracle.py`](../../permutation_shortcut_index_oracle.py).
Independent verifier: [`permutation_shortcut_index_verifier_oracle.py`](../../permutation_shortcut_index_verifier_oracle.py).

| Language | Source |
|---|---|
| C | [`c/p/permutation_shortcut_index.c`](../../../c/p/permutation_shortcut_index.c) |
| C3 | [`c3/p/permutation_shortcut_index.c3`](../../../c3/p/permutation_shortcut_index.c3) |
| C++ | [`cpp/p/permutation_shortcut_index.cpp`](../../../cpp/p/permutation_shortcut_index.cpp) |
| Elisa | [`elisa/p/permutation_shortcut_index.elisa`](../../../elisa/p/permutation_shortcut_index.elisa) |
| Nim | [`nim/p/permutation_shortcut_index.nim`](../../../nim/p/permutation_shortcut_index.nim) |
| Odin | [`odin/p/permutation_shortcut_index.odin`](../../../odin/p/permutation_shortcut_index.odin) |
| Rust | [`rust/p/permutation_shortcut_index.rs`](../../../rust/p/permutation_shortcut_index.rs) |
| V | [`v/p/permutation_shortcut_index.v`](../../../v/p/permutation_shortcut_index.v) |
| Zig | [`zig/p/permutation_shortcut_index.zig`](../../../zig/p/permutation_shortcut_index.zig) |
