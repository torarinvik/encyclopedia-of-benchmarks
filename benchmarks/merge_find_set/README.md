# Merge-find set

This benchmark ports the pinned Haskell disjoint-set implementation. It starts
with the integer set `0..n-1`, applies a bounded sequence of merges in order,
then returns the representative found for one requested element.

## Contract

The `i64_array_scalar` input is
`[n, merge_count, x0, y0, ..., x(m-1), y(m-1), query]`. The initial set
contains every integer from 0 through `n-1`, where `n` is in 1..256. The merge
count `m` is in 0..512; each merge endpoint and the final query element must be
in 0..n-1. The input must contain exactly `2*m+3` signed 64-bit words.

The scalar result is the representative returned by `find(query)` after all
merges. `find` follows parent links without path compression. `merge` first
finds both roots, attaches the lower-rank root under the higher-rank root, and
on equal ranks attaches the first root under the second and increments the
second root's rank. Re-merging elements already in one set leaves the maps
unchanged. Malformed input returns `-1`.

The oracle uses an iterative parent walk and applies the same specified rank
and tie rules. The workload covers both unequal-rank orientations as well as
equal-rank ties. All addressed elements are initialized in the set, matching
the source's precondition that queried elements are present.

## Pinned source

- TheAlgorithms/Haskell [`src/SpecializedStructure/MergeFindSet.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/SpecializedStructure/MergeFindSet.hs), commit `9dcabef99fb8995a760ff25a9e0d659114c0b9d3`

The source stores parent and rank maps, initializes every element as its own
parent at rank zero, recursively follows parent links without compression,
and applies union by rank. Its equal-rank branch preserves argument order by
attaching the first root under the second.

## Workload

The workload is [`workload.json`](workload.json); the independent iterative
oracle is [`benchmarks/merge_find_set_oracle.py`](../merge_find_set_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [`c/m/merge_find_set.c`](../../c/m/merge_find_set.c) |
| C3 | [`c3/m/merge_find_set.c3`](../../c3/m/merge_find_set.c3) |
| C++ | [`cpp/m/merge_find_set.cpp`](../../cpp/m/merge_find_set.cpp) |
| Elisa | [`elisa/m/merge_find_set.elisa`](../../elisa/m/merge_find_set.elisa) |
| Nim | [`nim/m/merge_find_set.nim`](../../nim/m/merge_find_set.nim) |
| Odin | [`odin/m/merge_find_set.odin`](../../odin/m/merge_find_set.odin) |
| Rust | [`rust/m/merge_find_set.rs`](../../rust/m/merge_find_set.rs) |
| V | [`v/m/merge_find_set.v`](../../v/m/merge_find_set.v) |
| Zig | [`zig/m/merge_find_set.zig`](../../zig/m/merge_find_set.zig) |

## Implementations

- C: [`c/m/merge_find_set.c`](../../c/m/merge_find_set.c)
- C3: [`c3/m/merge_find_set.c3`](../../c3/m/merge_find_set.c3)
- C++: [`cpp/m/merge_find_set.cpp`](../../cpp/m/merge_find_set.cpp)
- Elisa: [`elisa/m/merge_find_set.elisa`](../../elisa/m/merge_find_set.elisa)
- Nim: [`nim/m/merge_find_set.nim`](../../nim/m/merge_find_set.nim)
- Odin: [`odin/m/merge_find_set.odin`](../../odin/m/merge_find_set.odin)
- Rust: [`rust/m/merge_find_set.rs`](../../rust/m/merge_find_set.rs)
- V: [`v/m/merge_find_set.v`](../../v/m/merge_find_set.v)
- Zig: [`zig/m/merge_find_set.zig`](../../zig/m/merge_find_set.zig)
