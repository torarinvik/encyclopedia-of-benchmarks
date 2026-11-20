# Chess960 Scharnagl position unranking

This package decodes zero-based Scharnagl identifiers into the canonical
Chess960 first rank. It measures the constrained unranking operation itself:
four mixed-radix fields place the opposite-color bishops, queen, and knight
pair; the three remaining files receive rook, king, rook from left to right.
The supplied identifiers make every call deterministic.

## Bounded contract

The `i64_array_bytes_output` input is `[count, id_0, ..., id_(count-1)]`.
`count` is 0 through 960, each ID is 0 through 959, and the frame has exactly
`count+1` signed-i64 words. Duplicate IDs are accepted and appear repeatedly
in the output. Each output position is eight ASCII bytes in file order a
through h, using `B`, `N`, `R`, `Q`, and `K`. A nonempty batch writes `8*count`
bytes; an empty batch succeeds with zero bytes, including a null output. A
malformed frame or ID returns -1. A null output for nonempty output or short
capacity returns -2 without writes.

This profile uses the standard Scharnagl numbering map. It is distinct from
[`myrvold_ruskey_permutation_unrank`](../../m/myrvold_ruskey_permutation_unrank/README.md),
which un-ranks arbitrary permutations using a recursive swap-based factoradic
method. Here, only 960 constrained arrangements are ranked: the bishop digits
select opposite file colors, the queen selects one of six vacancies, and a
ten-way combination digit selects two of the remaining five files for
knights. It also differs from random shuffle-and-reject generation: this
benchmark does not sample or claim a stochastic distribution.

The valid input maximum is 961 words, the parseable maximum is 962, the output
maximum is 7,680 bytes, and the native workspace cap is 192 bytes excluding
caller-owned input/output. The direct unranker takes O(count) time and O(1)
scratch space. The independent reference enumerates the 5,040 unique
multiset arrangements, filters the chess constraints, reverse-ranks each
legal row, and uses an ID-indexed table; its time is O(5,040+count) and its
reference table uses 7,680 bytes.

## References and provenance

The RosettaGit [Generate Chess960 starting position task](https://rosettagit.org/tasks/generate-chess960-starting-position/)
provides discovery context and the bishop/king/rook constraints. The
number-to-position convention is checked against the Scharnagl/van Reem
[Chess960 rules and numbering tables](https://de.chessbase.com/portals/3/files/2006/scharnagl/chess960_regeln.pdf).
The position constraints are cross-checked against the [FIDE Chess960 rules](https://www.fide.com/docs/regulations/ARB%20Manual%202020.pdf).
No task text, source code, published examples, or test vectors were copied.
The input profile, fixtures, references, and ten language ports were written
for this package. See [RIGHTS.md](RIGHTS.md) for provenance notes.

## Workload and inventory

[`workload.json`](workload.json) covers interior IDs, a near-upper ID,
caller-order preservation, duplicates, empty output, malformed frames, and
output errors. [`verify_workload.py`](verify_workload.py) reconciles the
mixed-radix unranker with the legal-arrangement reverse-ranking reference and
checks all pinned bytes. [`check_inventory.py`](check_inventory.py) checks
package files, metadata, and ten source paths without executing native code.

| Language | Source |
|---|---|
| C | `c/c/chess960_scharnagl_position_unrank.c` |
| C3 | `c3/c/chess960_scharnagl_position_unrank.c3` |
| C++ | `cpp/c/chess960_scharnagl_position_unrank.cpp` |
| Elisa | `elisa/c/chess960_scharnagl_position_unrank.elisa` |
| Mojo | `mojo/c/chess960_scharnagl_position_unrank.mojo` |
| Nim | `nim/c/chess960_scharnagl_position_unrank.nim` |
| Odin | `odin/c/chess960_scharnagl_position_unrank.odin` |
| Rust | `rust/c/chess960_scharnagl_position_unrank.rs` |
| V | `v/c/chess960_scharnagl_position_unrank.v` |
| Zig | `zig/c/chess960_scharnagl_position_unrank.zig` |
