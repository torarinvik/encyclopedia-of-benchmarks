# Read-only integer-alphabet in-place suffix array

This package constructs a suffix array for a read-only integer string using
LMS naming and induced sorting. The bounded ports use the output array as the
sequence workspace, pack the fixed-size bucket metadata into a constant number
of machine words, and keep the input unchanged. Symbols in the caller's
alphabet `[0,n-1]` are shifted to `[1,n]`; the ports append an internal zero
sentinel and omit its suffix from the returned vector. This is a bounded
`d=1` specialization of the read-only integer-alphabet framework in Section 4
of the cited paper. The fixed alphabet lets the ports replace the paper's
succinct select/pointer storage and two-stage split with fixed four-word
packed bucket/cursor tables. The output buffer holds every variable-length
suffix-index sequence; the ports do not use an O(n) type map, bucket array,
reduced-string array, or suffix-slice comparison.

## Bounded contract

The ABI is `i64_array_bytes_output` with exported symbol
`suffix_array_inplace_readonly_integer`. Input is exactly
`[text_length, symbol_0, ..., symbol_(n-1)]`, where `0 <= n <= 32` and each
symbol is in `[0,n-1]`. The returned byte vector is the zero-based suffix-start
permutation in lexicographic order, encoded as little-endian signed 64-bit
integers. The internal sentinel suffix is not returned.

The caller's output buffer doubles as the suffix-array workspace, so it must
hold `8*(n+1)` bytes even though success returns only `8*n` bytes. Empty text
returns `0` after the same non-null workspace check. Malformed or out-of-profile
input returns `-1`; null output or insufficient workspace capacity returns
`-2`, with no writes on errors. The maximum returned vector is 256 bytes and
the maximum required output workspace is 264 bytes. Input is read-only.

The ten bounded ports use at most 2,048 bytes of algorithm-owned call-frame
state across the maximum five recursive levels. Per-symbol counters and
bucket cursors are packed into fixed four-word tables; LMS positions, reduced
names, and seed lists each fit in two packed words. The output buffer contains
all suffix-index sequences and must be `8*(n+1)` bytes even though the result
is only `8*n` bytes. This is a bounded adaptation of the paper's read-only
integer construction, not a claim to implement its general succinct select
structure or its two-stage pointer-storage schedule.

## Distinction and references

[`suffix_array_sais`](../suffix_array_sais/README.md) implements conventional
SA-IS with explicit O(n + sigma) type, bucket, and reduced-string arrays.
This package preserves the read-only input and in-place workspace profile of
the Section 4 method, using packed fixed-domain state and caller-provided SA
storage. [`suffix_array`](../suffix_array/README.md) uses rank doubling, and
[`suffix_array_dc3`](../suffix_array_dc3/README.md) uses modulo-three sample
sorting.

The [primary reference](primary_oracle.py) follows the LMS reduction and
induced-sorting recurrence. The [independent reference](independent_oracle.py)
orders complete suffixes directly. The [workload](workload.json) includes
empty, singleton, repeated, periodic, maximum-length, malformed, and output
capacity cases. [`verify_workload.py`](verify_workload.py) statically checks
fixture agreement, provenance, metadata, and all ten source paths.

## Provenance

Zhize Li, Jian Li, and Hongwei Huo, “Optimal In-Place Suffix Sorting,”
*Information and Computation*, [DOI 10.1016/j.ic.2021.104818](https://doi.org/10.1016/j.ic.2021.104818),
[arXiv:1610.08305](https://arxiv.org/html/1610.08305), Section 4. The OI Wiki
[Optimal In-place Suffix Sort](https://en.oi-wiki.org/string/sa-optimal-inplace/)
article was used for discovery and cross-checking. The source descriptions
only were consulted; code, wording, and fixtures are clean-room.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/suffix_array_inplace_readonly_integer.c`](../../../c/s/suffix_array_inplace_readonly_integer.c) |
| C3 | [`c3/s/suffix_array_inplace_readonly_integer.c3`](../../../c3/s/suffix_array_inplace_readonly_integer.c3) |
| C++ | [`cpp/s/suffix_array_inplace_readonly_integer.cpp`](../../../cpp/s/suffix_array_inplace_readonly_integer.cpp) |
| Elisa | [`elisa/s/suffix_array_inplace_readonly_integer.elisa`](../../../elisa/s/suffix_array_inplace_readonly_integer.elisa) |
| Mojo | [`mojo/s/suffix_array_inplace_readonly_integer.mojo`](../../../mojo/s/suffix_array_inplace_readonly_integer.mojo) |
| Nim | [`nim/s/suffix_array_inplace_readonly_integer.nim`](../../../nim/s/suffix_array_inplace_readonly_integer.nim) |
| Odin | [`odin/s/suffix_array_inplace_readonly_integer.odin`](../../../odin/s/suffix_array_inplace_readonly_integer.odin) |
| Rust | [`rust/s/suffix_array_inplace_readonly_integer.rs`](../../../rust/s/suffix_array_inplace_readonly_integer.rs) |
| V | [`v/s/suffix_array_inplace_readonly_integer.v`](../../../v/s/suffix_array_inplace_readonly_integer.v) |
| Zig | [`zig/s/suffix_array_inplace_readonly_integer.zig`](../../../zig/s/suffix_array_inplace_readonly_integer.zig) |
