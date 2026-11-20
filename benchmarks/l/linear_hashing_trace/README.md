# Linear hashing operation trace

This bounded profile measures Litwin-style linear hashing for a dynamic set of
signed integer keys. The bucket directory expands one bucket at a time using a
split pointer; it does not double and rehash the entire table at each growth
step. This is distinct from the repository's cuckoo-hashing insertion and
displacement profile.

## Contract

- Input is `[Q,(opcode,key)*Q]`, with `0<=Q<=63` and keys in `[-1024,1023]`.
- Opcode `0` inserts an absent key; `1` deletes a present key; `2` tests
  membership. Each operation succeeds with bit `1`; duplicate insertions,
  absent deletions, and absent membership queries produce bit `0`.
- The result packs operation bits in trace order, with the first operation in
  the most-significant used bit. `Q=0` returns zero. A null frame, malformed
  length, unknown opcode, or out-of-range key returns `-1`.
- The table begins with two buckets, split level `i=1`, and split pointer
  `p=0`. After a successful insertion, if live keys exceed twice the current
  bucket count, split exactly the bucket at `p`. Rehash its entries using
  `h_(i+1)`, advance `p`, and when `p=2^i`, increment `i` and reset `p=0`.
  Buckets use separate chaining. The profile caps the directory at 32 buckets;
  it does not merge buckets after deletions.
- A key is assigned by `h_i(k)=k mod 2^i`; if `h_i(k)<p`, use
  `h_(i+1)(k)`. Modulo is Euclidean, so negative keys map to nonnegative
  bucket indices.

The primary uses fixed arrays for bucket heads and chained entries and performs
the incremental split. The independent reference models only the observable
set semantics with a flat list and linear membership search. The implementation
uses `O(Q)` storage. Ordinary operations inspect one chain; a split scans the
entries of one bucket and moves them to its new partner.

## Provenance

The method was identified from NIST's [Dictionary of Algorithms and Data
Structures entry for linear hashing](https://xlinux.nist.gov/dads/HTML/linearHashing.html)
and specified from Litwin, [“Linear Hashing: A New Tool for File and Table
Addressing”](https://www.vldb.org/dblp/db/conf/vldb/Litwin80.html). The sources describe the
algorithm; all benchmark code and fixtures are clean-room. NIST was also used
to discover the candidate, and no source implementation or prose was copied.

## Suite and ports

The workload is registered in the shared `i64_array_scalar` suite. Its maximum
valid frame is 127 signed 64-bit words; one additional trailing word is within
the parse bound and must be rejected. The fixed workspace declaration is
8,192 bytes. Fixtures cross the first split threshold and query keys that stay
in the old bucket, move to its new partner, and remain in an unrelated bucket.

| Language | Port |
| --- | --- |
| C | [`c/l/linear_hashing_trace.c`](../../../c/l/linear_hashing_trace.c) |
| C3 | [`c3/l/linear_hashing_trace.c3`](../../../c3/l/linear_hashing_trace.c3) |
| C++ | [`cpp/l/linear_hashing_trace.cpp`](../../../cpp/l/linear_hashing_trace.cpp) |
| Elisa | [`elisa/l/linear_hashing_trace.elisa`](../../../elisa/l/linear_hashing_trace.elisa) |
| Mojo | [`mojo/l/linear_hashing_trace.mojo`](../../../mojo/l/linear_hashing_trace.mojo) |
| Nim | [`nim/l/linear_hashing_trace.nim`](../../../nim/l/linear_hashing_trace.nim) |
| Odin | [`odin/l/linear_hashing_trace.odin`](../../../odin/l/linear_hashing_trace.odin) |
| Rust | [`rust/l/linear_hashing_trace.rs`](../../../rust/l/linear_hashing_trace.rs) |
| V | [`v/l/linear_hashing_trace.v`](../../../v/l/linear_hashing_trace.v) |
| Zig | [`zig/l/linear_hashing_trace.zig`](../../../zig/l/linear_hashing_trace.zig) |
