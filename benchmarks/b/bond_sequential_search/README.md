# Bond Sequential Search

After validating the bounded input, Bond Sequential Search scans an unsorted
array for two distinct keys. It combines the keys with bitwise OR, uses the
composite as a candidate mask, and performs exact equality checks only when an
item contains no bits outside that mask. The first index of each key is
returned; either key may be absent.

This is distinct from two independent linear searches: the search phase scans
the array once, with a bitwise mask filter before up to two exact comparisons.
It also differs from [`double_linear_search`](../../d/double_linear_search/README.md),
which searches for one key by checking opposite array ends; Bond Search looks
for two keys with a forward candidate-mask scan. The benchmark reports both
indices in a packed scalar so the search result stays observable through the
scalar ABI.

## Contract

The `i64_array_scalar` input is `[n, key_a, key_b, values...]`, with exactly
`n+3` words and `0 <= n <= 64`. Keys must be distinct integers in `[0,255]`;
array values are also in `[0,255]`. The array is unsorted and may contain
duplicates. Empty arrays are valid.

The return value is `index_a * 65 + index_b`, with zero-based first-match
indices and sentinel `64` for an absent key. Thus an empty array returns
`4224`; malformed inputs, null input, equal keys, and out-of-range values
return `-1`. Valid frames have at most 67 words; one extra parseable word
allows the suite to check trailing-data rejection. The implementation reads
the input directly and uses no auxiliary workspace.

The scan forms `mask = key_a | key_b`. An array value is a candidate exactly
when `(value & mask) == value`; exact comparisons then record the first match
for each key. Since values are nonnegative bytes, the mask test is a portable
subset-of-bits filter. The complete call performs an input-validation pass
and a search pass, so worst-case time is `O(n)` and auxiliary space is `O(1)`.

## Workload and provenance

[`workload.json`](workload.json) covers both encounter orders, repeated
values, candidate false positives, one or both absent keys, empty and maximum
arrays, null input, invalid domains, equal keys, and malformed frames. The
primary oracle mirrors the composite-mask scan. The independent oracle uses
two direct linear searches and packs their first-match indices independently.

The algorithm idea is attributed to the NIST Dictionary of Algorithms and
Data Structures entry for
[Bond Sequential Search](https://xlinux.nist.gov/dads/HTML/BondSeqSearch.html)
and Abu El Haija and Alazzam's [Bond-Sequential Search paper](https://www.iaeng.org/publication/WCECS2012/WCECS2012_pp194-198.pdf).
All ports, references, fixtures, and prose are independently written; no
source code, pseudocode, tests, or examples were copied. See
[`RIGHTS.md`](RIGHTS.md) and [`INVENTORY.md`](INVENTORY.md).

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/b/bond_sequential_search.c`](../../../c/b/bond_sequential_search.c) |
| C3 | [`c3/b/bond_sequential_search.c3`](../../../c3/b/bond_sequential_search.c3) |
| C++ | [`cpp/b/bond_sequential_search.cpp`](../../../cpp/b/bond_sequential_search.cpp) |
| Elisa | [`elisa/b/bond_sequential_search.elisa`](../../../elisa/b/bond_sequential_search.elisa) |
| Mojo | [`mojo/b/bond_sequential_search.mojo`](../../../mojo/b/bond_sequential_search.mojo) |
| Nim | [`nim/b/bond_sequential_search.nim`](../../../nim/b/bond_sequential_search.nim) |
| Odin | [`odin/b/bond_sequential_search.odin`](../../../odin/b/bond_sequential_search.odin) |
| Rust | [`rust/b/bond_sequential_search.rs`](../../../rust/b/bond_sequential_search.rs) |
| V | [`v/b/bond_sequential_search.v`](../../../v/b/bond_sequential_search.v) |
| Zig | [`zig/b/bond_sequential_search.zig`](../../../zig/b/bond_sequential_search.zig) |
