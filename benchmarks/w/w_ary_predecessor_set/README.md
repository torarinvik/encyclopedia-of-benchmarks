# 64-ary bitmap predecessor set

This package implements a dynamic ordered set over the fixed universe
`0..262143`. Three bitmap levels represent keys, nonempty 64-key blocks, and
nonempty groups of blocks. Successor and predecessor queries inspect a local
word, then use summary words to jump directly to the next nonempty block.
The hierarchy has fanout 64 at each level and never scans all keys or all
blocks.

## Contract

The scalar ABI and exported symbol are `i64_array_scalar` and
`w_ary_predecessor_set`. Input is `[q, (opcode, key)*q]`, where
`0 <= q <= 32`, keys are in `0..262143`, and each operation is:

- `0, key`: insert; return `1` if the key was absent, otherwise `0`.
- `1, key`: erase; return `1` if the key was present, otherwise `0`.
- `2, key`: contains; return `1` if present, otherwise `0`.
- `3, key`: inclusive successor; return the least present key `>= key`, plus
  one, or `0` if none exists.
- `4, key`: strict predecessor; return the greatest present key `< key`, plus
  one, or `0` if none exists.

Updates are idempotent. The scalar output is the sum of each response weighted
by its one-based operation index. Unknown operations, keys outside the
universe, null input, and any length other than `1 + 2*q` return `-1`. The
maximum valid and parseable lengths are 65 and 66 signed 64-bit words. All
responses are at most 262144, and the scalar result is at most 138412032.

## Distinction

The local [`veb_tree`](../../v/veb_tree/README.md) uses recursive
van Emde Boas splitting. The local
[`predecessor_problem`](../../p/predecessor_problem/README.md) uses packed
bitset predecessor/successor scans. This profile uses a fixed 64-ary hierarchy
of word summaries: a query checks one key word and climbs at most two levels
to find another nonempty word, then descends through summaries. It is a
separate representation and traversal strategy.

## References and review

The source idea is NyaanNyaan/library's
[`w-ary-tree.hpp`](https://github.com/NyaanNyaan/library/blob/master/data-structure/w-ary-tree.hpp),
which describes a dynamic set with 64-way bitmap summaries and predecessor /
successor navigation. The package fixes a bounded universe and specifies the
scalar ABI and edge cases independently. No source code, prose, examples, or
fixtures were copied. See [`RIGHTS.md`](RIGHTS.md) for source and license notes.

The primary oracle implements the three-level bitmap traversal. The
independent oracle uses a sorted-set model with direct neighbor selection.
[`workload.json`](workload.json) records manually derived outputs, including a
maximum frame that jumps across hierarchy groups. The package checker reviews
fixture values, Markdown targets, and source inventory. The ports have not been
compiled or run.

| Language | Source |
|---|---|
| C | [`c/w/w_ary_predecessor_set.c`](../../../c/w/w_ary_predecessor_set.c) |
| C3 | [`c3/w/w_ary_predecessor_set.c3`](../../../c3/w/w_ary_predecessor_set.c3) |
| C++ | [`cpp/w/w_ary_predecessor_set.cpp`](../../../cpp/w/w_ary_predecessor_set.cpp) |
| Elisa | [`elisa/w/w_ary_predecessor_set.elisa`](../../../elisa/w/w_ary_predecessor_set.elisa) |
| Mojo | [`mojo/w/w_ary_predecessor_set.mojo`](../../../mojo/w/w_ary_predecessor_set.mojo) |
| Nim | [`nim/w/w_ary_predecessor_set.nim`](../../../nim/w/w_ary_predecessor_set.nim) |
| Odin | [`odin/w/w_ary_predecessor_set.odin`](../../../odin/w/w_ary_predecessor_set.odin) |
| Rust | [`rust/w/w_ary_predecessor_set.rs`](../../../rust/w/w_ary_predecessor_set.rs) |
| V | [`v/w/w_ary_predecessor_set.v`](../../../v/w/w_ary_predecessor_set.v) |
| Zig | [`zig/w/w_ary_predecessor_set.zig`](../../../zig/w/w_ary_predecessor_set.zig) |
