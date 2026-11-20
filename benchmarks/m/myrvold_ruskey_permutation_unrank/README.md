# Myrvold–Ruskey permutation unranking

This package un-ranks a permutation of `0..n-1` by Myrvold and Ruskey's first
linear-time procedure. It initializes the identity permutation and, for sizes
`n` down to one, swaps position `size-1` with `rank mod size`, then replaces
the rank by `floor(rank/size)`. This induced permutation order is
non-lexicographic.

## Contract

The exported byte-output function accepts the signed-i64 frame `[n, rank]`.
`n` is in `0..8`; `rank` must satisfy `0 <= rank < n!`, so `[0,0]` is the
single valid empty-permutation request. A valid result contains the permutation
labels as `n` little-endian signed-i64 words. It returns the byte count `8*n`.
For `n=0`, a non-null output pointer with capacity zero is a successful
zero-byte result. A null output pointer or insufficient capacity returns
`-2`; malformed input returns `-1` before output validation. The function
never writes output on error.

The valid input frame is exactly two words; one trailing word is parseable but
invalid. Maximum output is 64 bytes and the native workspace cap is 256 bytes,
including the eight-entry permutation buffer, scalar state, and alignment.

## Algorithm distinction

The local [`kth_lexicographic_permutation`](../../k/kth_lexicographic_permutation/README.md)
selects from lexicographic order by factorial blocks and element removal. This
package follows a different, non-lexicographic order defined by the
Myrvold–Ruskey swap sequence and runs in `O(n)` time. It does not add another
implementation of lexicographic unranking.

The primary reference applies the mixed-radix swap sequence. The independent
reference enumerates candidate permutations and ranks each by the inverse
Myrvold–Ruskey recurrence; this bounded reference takes `O(n*n!)` time and
`O(n)` candidate space. Fixtures include the empty and singleton cases,
interior ranks, maximum rank, the maximum output, capacity failure, malformed
frames, and null input/output.

## Sources and files

NIST DADS provides title-level discovery and cites the linear-time method:
[unranking](https://xlinux.nist.gov/dads/HTML/unrank.html). The pinned
algorithm is Algorithm 1 in Wendy Myrvold and Frank Ruskey, “Ranking and
Unranking Permutations in Linear Time,” *Information Processing Letters* 79
(2001), 281–284, [DOI 10.1016/S0020-0190(01)00141-7](https://doi.org/10.1016/S0020-0190(01)00141-7),
[author PDF](https://webhome.cs.uvic.ca/~ruskey/Publications/RankPerm/MyrvoldRuskey.pdf).

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py),
[`verify_workload.py`](verify_workload.py), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md). The package has ten language ports:

| Language | Source |
| --- | --- |
| C | [`c/m/myrvold_ruskey_permutation_unrank.c`](../../../c/m/myrvold_ruskey_permutation_unrank.c) |
| C3 | [`c3/m/myrvold_ruskey_permutation_unrank.c3`](../../../c3/m/myrvold_ruskey_permutation_unrank.c3) |
| C++ | [`cpp/m/myrvold_ruskey_permutation_unrank.cpp`](../../../cpp/m/myrvold_ruskey_permutation_unrank.cpp) |
| Elisa | [`elisa/m/myrvold_ruskey_permutation_unrank.elisa`](../../../elisa/m/myrvold_ruskey_permutation_unrank.elisa) |
| Mojo | [`mojo/m/myrvold_ruskey_permutation_unrank.mojo`](../../../mojo/m/myrvold_ruskey_permutation_unrank.mojo) |
| Nim | [`nim/m/myrvold_ruskey_permutation_unrank.nim`](../../../nim/m/myrvold_ruskey_permutation_unrank.nim) |
| Odin | [`odin/m/myrvold_ruskey_permutation_unrank.odin`](../../../odin/m/myrvold_ruskey_permutation_unrank.odin) |
| Rust | [`rust/m/myrvold_ruskey_permutation_unrank.rs`](../../../rust/m/myrvold_ruskey_permutation_unrank.rs) |
| V | [`v/m/myrvold_ruskey_permutation_unrank.v`](../../../v/m/myrvold_ruskey_permutation_unrank.v) |
| Zig | [`zig/m/myrvold_ruskey_permutation_unrank.zig`](../../../zig/m/myrvold_ruskey_permutation_unrank.zig) |

The profile is registered with the shared `i64_array_bytes_output`
runner/verifier and catalog. No code, article text, examples, or fixtures were reused. No programs, tests,
scripts, checkers, builds, compilers, profilers, or benchmarks were run.
