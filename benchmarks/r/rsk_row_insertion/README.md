# Robinson–Schensted–Knuth row insertion

This bounded profile applies row insertion to a permutation and returns an
injective encoding of the insertion tableau `P` and recording tableau `Q`. It
is distinct from [`hook_length_tableaux`](../../h/hook_length_tableaux/README.md),
which counts standard tableaux from a supplied shape without constructing an
RSK pair.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is `rsk_row_insertion`.
Input is `[n, permutation[0], ..., permutation[n-1]]`, with `0 <= n <= 8` and
the values `0..n-1` appearing once each. The empty permutation is encoded by
`[0]`. A null input, malformed count, wrong length, duplicate, out-of-range
value, or overlength input returns `INT64_MIN`.

The permutation values are shifted to `1..n` for the tableau construction.
For each insertion, `P` receives the value by bumping the first strictly larger
entry in each row; `Q` receives the one-based insertion step in the newly added
corner cell. Both are standard Young tableaux of the same shape.

## Output encoding and complexity

The scalar is a base-9 digit stream. Its first digit is `n`; for each label
`1..n`, append the row of that label in `P` plus one, followed by its row in
`Q` plus one. Thus all following digits are in `1..8`, and there are exactly
`2n` of them. The `n` prefix fixes the digit count; counts of row digits recover
the shape, so the code uniquely identifies both tableaux including their row
boundaries. RSK itself uniquely identifies each valid permutation.

At most 17 base-9 digits are used. The conservative bound `9^17-1` is
16,677,181,699,666,568, within signed `i64`; the maximum-length identity
fixture returns 15,055,789,034,421,208. Row insertion takes `O(n^2)` time and
`O(n^2)` space in this bounded representation.

The primary reference performs forward row bumping. The independent reference
enumerates all pairs of standard tableaux with a common shape, applies reverse
row insertion, and matches the recovered permutation. It does not call the
forward primary reference.

## Provenance

The method is described by OI Wiki English in its [Young Tableau
article](https://www.timothywang.ca/OI-wiki/math/young-tableau/). This package
uses the mathematical idea only; see [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/r/rsk_row_insertion.c`](../../../c/r/rsk_row_insertion.c) |
| C3 | [`c3/r/rsk_row_insertion.c3`](../../../c3/r/rsk_row_insertion.c3) |
| C++ | [`cpp/r/rsk_row_insertion.cpp`](../../../cpp/r/rsk_row_insertion.cpp) |
| Elisa | [`elisa/r/rsk_row_insertion.elisa`](../../../elisa/r/rsk_row_insertion.elisa) |
| Mojo | [`mojo/r/rsk_row_insertion.mojo`](../../../mojo/r/rsk_row_insertion.mojo) |
| Nim | [`nim/r/rsk_row_insertion.nim`](../../../nim/r/rsk_row_insertion.nim) |
| Odin | [`odin/r/rsk_row_insertion.odin`](../../../odin/r/rsk_row_insertion.odin) |
| Rust | [`rust/r/rsk_row_insertion.rs`](../../../rust/r/rsk_row_insertion.rs) |
| V | [`v/r/rsk_row_insertion.v`](../../../v/r/rsk_row_insertion.v) |
| Zig | [`zig/r/rsk_row_insertion.zig`](../../../zig/r/rsk_row_insertion.zig) |
