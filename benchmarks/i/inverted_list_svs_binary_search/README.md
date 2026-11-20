# Inverted-list shortest-first binary-search intersection

This package implements the small-versus-small (SvS) full-intersection
algorithm for a bounded family of sorted integer posting lists. It sorts list
IDs by `(length, original ID)`, initializes the candidate sequence from the
shortest list, and visits the remaining lists in that order. For each later
list, it binary-searches each surviving candidate in the suffix beginning at
the previous lower-bound position. A found value advances that position past
the match; a missing value advances it to the insertion point. Thus every
search is monotone and candidates remain in ascending order.

## Contract

The exported symbol is `inverted_list_svs_binary_search` with the
`i64_array_bytes_output` ABI. Input is a packed signed 64-bit array:

```text
[k, n0, values0..., n1, values1..., ..., n(k-1), values(k-1)...]
```

- `2 <= k <= 8` and `0 <= n_i <= 32`.
- Every list is strictly increasing; each value must fit signed 32-bit.
- The frame length is exactly `1 + sum(1+n_i)`. The maximum valid frame is
  `1 + 8*(1+32) = 265` words. Parsers accept at most 266 words so a trailing
  word is rejected explicitly.
- Output is the unique intersection in ascending order, encoded as consecutive
  little-endian signed 32-bit values with no count header. The return value is
  the number of values written. An empty intersection returns zero and writes
  zero bytes.
- Capacity must hold `4*min(n_i)` bytes, the maximum possible result size. A
  malformed input returns `-1`; a null output when that bound is nonzero or an
  insufficient capacity returns `-2`. Errors leave output untouched.
- Maximum output and declared scratch workspace are 128 and 4,096 bytes. The
  native ports retain at most three eight-entry metadata arrays (192 bytes on
  a 64-bit target) and a 32-value candidate array (at most 256 bytes); no
  recursive or input-sized state is allocated. The cap leaves ample room for
  scalar locals and ABI-level call frames.

The primary algorithm takes `O(sum(n_i) + k^2 + k*m*log(33))` comparisons in
this bounded profile, where `m=min(n_i)`, and uses `O(k+m)` words of scratch. The
independent reference instead builds membership sets and filters the shortest
list directly; it does not use the search cursor or binary search.

## Source distinction

The package is based on the SvS procedure in §3 of Demaine, López-Ortiz, and
Munro, “Experiments on Adaptive Set Intersections for Text Retrieval
Systems,” and on the Chapter 628 entry “Intersections of Inverted Lists.” The
paper specifies
sorting the lists by size, retaining the shortest as candidates, and binary
searching each later list from the preceding lower-bound position. This is a
clean-room bounded implementation of that procedure; it does not reproduce
source code or paper fixtures.

This is distinct from the local three-list simultaneous DAAT cursor
intersection, which advances current heads together; the fixed `k=3,t=2`
threshold algorithm, which returns values present in at least two lists; and
the dense bitvector intersection, which performs word-wise AND. It measures
shortest-first candidate filtering with repeated monotone binary searches.

Sources:

- [Encyclopedia of Algorithms, Chapter 628](https://doi.org/10.1007/978-1-4939-2864-4_628)
- [Demaine, López-Ortiz, and Munro, §3, “Experiments on Adaptive Set Intersections for Text Retrieval Systems”](https://cs.uwaterloo.ca/~alopez-o/files/EoASIfTRS_2001.pdf)

[`workload.json`](workload.json) pins empty, reordered, sparse, negative and
boundary-valued, maximum-size, malformed, null, and capacity cases. The
primary and independent references are package-local. [`verify_workload.py`](verify_workload.py)
and [`check_inventory.py`](check_inventory.py) provide static consistency
helpers; they are source artifacts and are not run here. See [`RIGHTS.md`](RIGHTS.md)
for provenance and [`INVENTORY.md`](INVENTORY.md) for all ten language ports.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/i/inverted_list_svs_binary_search.c`](../../../c/i/inverted_list_svs_binary_search.c) |
| C3 | [`c3/i/inverted_list_svs_binary_search.c3`](../../../c3/i/inverted_list_svs_binary_search.c3) |
| C++ | [`cpp/i/inverted_list_svs_binary_search.cpp`](../../../cpp/i/inverted_list_svs_binary_search.cpp) |
| Elisa | [`elisa/i/inverted_list_svs_binary_search.elisa`](../../../elisa/i/inverted_list_svs_binary_search.elisa) |
| Mojo | [`mojo/i/inverted_list_svs_binary_search.mojo`](../../../mojo/i/inverted_list_svs_binary_search.mojo) |
| Nim | [`nim/i/inverted_list_svs_binary_search.nim`](../../../nim/i/inverted_list_svs_binary_search.nim) |
| Odin | [`odin/i/inverted_list_svs_binary_search.odin`](../../../odin/i/inverted_list_svs_binary_search.odin) |
| Rust | [`rust/i/inverted_list_svs_binary_search.rs`](../../../rust/i/inverted_list_svs_binary_search.rs) |
| V | [`v/i/inverted_list_svs_binary_search.v`](../../../v/i/inverted_list_svs_binary_search.v) |
| Zig | [`zig/i/inverted_list_svs_binary_search.zig`](../../../zig/i/inverted_list_svs_binary_search.zig) |
