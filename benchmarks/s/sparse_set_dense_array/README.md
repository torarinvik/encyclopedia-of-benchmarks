# Sparse set with dense and sparse arrays

This benchmark implements the fixed-universe sparse-set representation of
Briggs and Torczon. The set stores its active keys contiguously in a dense
array and keeps a sparse inverse index from each possible key back to its
dense position. Membership uses a bounds check and a back-pointer check, so
stale sparse entries remain harmless after erase or clear.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`sparse_set_dense_array`. Input is `[universe_size,operation_count,(opcode,key)*]`
with universe size 1..32, operation count 0..30, and exact length
`2+2*operation_count`. Keys are in `[0,universe_size)`. Opcodes are 0 insert,
1 erase, 2 membership query, and 3 clear; clear requires key zero. Invalid and
null input returns `-1`. Maximum valid and parseable lengths are 62 and 63
words.

Insert and erase return one when they change the set and zero otherwise;
membership returns one when present; clear returns one if the set was
nonempty. Pack these booleans in operation order into the low
`operation_count` bits. The high field is the final membership mask, with bit
`k` set for each key `k` in the final set. The scalar is
`(final_mask << operation_count) | answer_bits`; it is at most `2^62-1`.

At call start, the sparse array is initialized to the universe size, a
sentinel outside every valid dense index. For a key `x`, membership is exactly
`sparse[x] < size && dense[sparse[x]] == x`. Insert appends a missing key and
sets its back-pointer. Erase replaces a removed dense slot with the final
active key and repairs that key's back-pointer. Clear only resets `size`, so
stale entries fail the membership check. Updates, membership, and clear are
O(1); initial sentinel setup is O(universe size), and final mask extraction
iterates the dense prefix in O(set size).

This differs from [`grow_only_set`](../../g/grow_only_set/README.md), which has
replica merge but no deletion or constant-time clear, and from
[`hash_set`](../../h/hash_set/README.md), which resolves membership through hash
buckets. It also differs from bitmap workloads, which store one bit per key
and clear by scanning or resetting the bit vector.

## Provenance

The representation follows Preston Briggs and Linda Torczon's “An Efficient
Representation for Sparse Sets,” *ACM Letters on Programming Languages and
Systems* 2(1–4), 59–69 (1993), [DOI
10.1145/176454.176484](https://doi.org/10.1145/176454.176484). An [available
paper copy](https://www.dcs.gla.ac.uk/~pat/ads2/papers/sparseSets.pdf) describes
the dense/sparse membership invariant and constant-time update operations. The
ports use the algorithmic representation only; no paper code or prose is
copied. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/s/sparse_set_dense_array.c](../../../c/s/sparse_set_dense_array.c) |
| C3 | [c3/s/sparse_set_dense_array.c3](../../../c3/s/sparse_set_dense_array.c3) |
| C++ | [cpp/s/sparse_set_dense_array.cpp](../../../cpp/s/sparse_set_dense_array.cpp) |
| Elisa | [elisa/s/sparse_set_dense_array.elisa](../../../elisa/s/sparse_set_dense_array.elisa) |
| Mojo | [mojo/s/sparse_set_dense_array.mojo](../../../mojo/s/sparse_set_dense_array.mojo) |
| Nim | [nim/s/sparse_set_dense_array.nim](../../../nim/s/sparse_set_dense_array.nim) |
| Odin | [odin/s/sparse_set_dense_array.odin](../../../odin/s/sparse_set_dense_array.odin) |
| Rust | [rust/s/sparse_set_dense_array.rs](../../../rust/s/sparse_set_dense_array.rs) |
| V | [v/s/sparse_set_dense_array.v](../../../v/s/sparse_set_dense_array.v) |
| Zig | [zig/s/sparse_set_dense_array.zig](../../../zig/s/sparse_set_dense_array.zig) |

`primary_oracle.py` uses dense/sparse inverse arrays. The structurally
independent `independent_oracle.py` uses a direct language-level set. The
workload covers duplicate insertion, unsuccessful erase, swap-delete repair,
stale indices after clear, the maximum frame, and malformed input. The static
inventory checker checks files and fixture metadata without executing the
benchmark.
