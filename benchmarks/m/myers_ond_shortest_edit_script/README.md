# Myers O(ND) shortest edit script

This byte-output benchmark reconstructs one deterministic minimum script of
insertions and deletions that transforms one byte sequence into another. It is
separate from [`myers_bitvector_edit_distance`](../myers_bitvector_edit_distance/README.md),
which returns global Levenshtein distance with substitutions allowed, and from
[`hirschberg_lcs`](../../h/hirschberg_lcs/README.md), which returns an LCS witness
using linear-space divide and conquer. This profile emits a replayable edit
path using Myers's furthest-reaching D-path search.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `myers_ond_shortest_edit_script`.
- Input: `[n,m,A...,B...]`, with `0<=n,m<=16`, each symbol in `0..255`, and
  exactly `2+n+m` signed 64-bit words. Maximum valid input is 34 words and
  maximum parseable input is 36 words.
- Invalid or null input returns `-1`. A null output or capacity smaller than
  the encoded script returns `-2`; no bytes are written on error. Input
  validation takes precedence over output errors.
- Output is a byte stream with tags `0` for a match/copy, `1` for deletion,
  and `2` followed by one literal byte for insertion. A match consumes the
  next input-A byte and emits it; deletion consumes the next input-A byte;
  insertion emits its following byte. The stream must consume all of A and
  produce exactly B. The edit cost is the number of `1` and `2` tags; an
  insertion payload byte is not an additional edit.
- The caller output workspace is 48 bytes. The result length is the number of
  script bytes; identical empty sequences return length zero.

## Algorithm and deterministic tie rule

In the edit graph, diagonal `k=x-y` stores the greatest reachable `x` after
exactly `d` non-diagonal edges. The search considers `k=-d,-d+2,...,d` and
greedily advances over the maximal run of equal bytes after each insertion or
deletion. Per-depth frontier snapshots make it possible to backtrack the
selected path and emit the instruction stream.

At an interior diagonal, choose the insertion predecessor only when
`V[k-1] < V[k+1]`; on equality, choose the deletion predecessor. The sweep
order is increasing diagonal, and each snake consumes equal bytes until the
next mismatch or sequence boundary. This follows the strict comparison and
furthest-reaching recurrence in Figure 2 of Myers's paper. The primary uses
`O((n+m)D)` time and `O(D^2)` frontier-snapshot space, plus `O(n+m)` path
storage, where `D` is the minimum insert/delete cost.

The independent reference builds a full prefix cost table in `O(nm)` time,
uses its own deletion-first local traceback tie rule, and checks that any
emitted stream replays exactly and has the optimal insert/delete cost. Its
tie rule is intentionally independent, so its witness can differ byte for
byte while remaining optimal.

## Provenance and rights

The primary source is Eugene W. Myers, [“An O(ND) Difference Algorithm and Its
Variations”](https://doi.org/10.1007/BF01840446), *Algorithmica* 1 (1986),
251–266. The paper describes shortest edit scripts as paths in an edit graph
and derives the furthest-reaching D-path algorithm. Only algorithm ideas are
used; no paper text, source code, figures, examples, or test data are copied.

## Language ports

| Language | Source |
|---|---|
| C | [myers_ond_shortest_edit_script.c](../../../c/m/myers_ond_shortest_edit_script.c) |
| C3 | [myers_ond_shortest_edit_script.c3](../../../c3/m/myers_ond_shortest_edit_script.c3) |
| C++ | [myers_ond_shortest_edit_script.cpp](../../../cpp/m/myers_ond_shortest_edit_script.cpp) |
| Elisa | [myers_ond_shortest_edit_script.elisa](../../../elisa/m/myers_ond_shortest_edit_script.elisa) |
| Mojo | [myers_ond_shortest_edit_script.mojo](../../../mojo/m/myers_ond_shortest_edit_script.mojo) |
| Nim | [myers_ond_shortest_edit_script.nim](../../../nim/m/myers_ond_shortest_edit_script.nim) |
| Odin | [myers_ond_shortest_edit_script.odin](../../../odin/m/myers_ond_shortest_edit_script.odin) |
| Rust | [myers_ond_shortest_edit_script.rs](../../../rust/m/myers_ond_shortest_edit_script.rs) |
| V | [myers_ond_shortest_edit_script.v](../../../v/m/myers_ond_shortest_edit_script.v) |
| Zig | [myers_ond_shortest_edit_script.zig](../../../zig/m/myers_ond_shortest_edit_script.zig) |

`check_inventory.py` records the static port and fixture inventory. No
programs, tests, checkers, builds, compilers, profilers, or benchmarks have
been run.
