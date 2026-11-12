# SA-IS suffix-array construction

This package constructs the suffix array with SA-IS: classify suffixes as
L-type or S-type, identify LMS positions, induce their order, name the sorted
LMS substrings, recursively sort the reduced string, then induce the complete
suffix order. The byte alphabet is shifted to `1..=256` and a unique `0`
sentinel is appended internally; the returned array omits that sentinel.

## Bounded contract

The `i64_array_bytes_output` entry point is
`suffix_array_sais(input, length, output, capacity) -> i64`. Input is
`[text_length, byte_symbols...]`, with `text_length` in `0..=32`, symbols in
`0..=255`, and exactly `1 + text_length` signed 64-bit values. The result is
the zero-based suffix-start permutation encoded as little-endian signed 64-bit
integers. Empty text writes no bytes and returns `0`; a null output pointer
still returns `-2`. Invalid framing or symbols return `-1`; a null output
pointer or insufficient capacity returns `-2`, without writing. The maximum
output is 256 bytes. The fixed workspace budget is 32,768 bytes, covering
bounded recursive frames, bucket arrays, reduced names, and suffix-index
storage.

For alphabet size `sigma`, SA-IS takes `O(n + sigma)` time and `O(n + sigma)`
working space. Here `sigma=257` including the sentinel. Each reduced LMS string
has at most half as many symbols as its parent.

## Distinction and verification

[`suffix_array`](../suffix_array/README.md) uses rank doubling, while
[`suffix_array_dc3`](../suffix_array_dc3/README.md) uses modulo-three sample
sorting and a DC3 merge. This package uses LMS naming and induced bucket scans,
so it represents a separate suffix-array construction.

The [primary oracle](primary_oracle.py) follows the SA-IS reduction and
induction. The [independent oracle](independent_oracle.py) sorts complete
suffix slices directly. The [workload](workload.json) covers empty and
singleton strings, repeated and periodic symbols, NUL and high byte values,
ascending and descending distinct bytes, malformed frames, null buffers, and
short output capacity. The `i64_array_bytes_output` verifier adds all text
lengths, seeded random byte strings, and exact/short/null output-capacity
probes. [`verify_workload.py`](verify_workload.py) statically checks fixture
agreement, metadata, provenance, and the ten source paths.

## Provenance

SA-IS was introduced by Nong, Zhang, and Chan in “Linear Suffix Array
Construction by Almost Pure Induced-Sorting,” *2009 Data Compression
Conference*, pp. 193–202, [DOI 10.1109/DCC.2009.42](https://doi.org/10.1109/DCC.2009.42).
The [OI Wiki suffix-array chapter](https://oi-wiki.org/string/sa/) provides an
additional algorithm exposition. Both sources were consulted for algorithm
description only; implementation and fixtures are clean-room. See
[`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/suffix_array_sais.c`](../../../c/s/suffix_array_sais.c) |
| C3 | [`c3/s/suffix_array_sais.c3`](../../../c3/s/suffix_array_sais.c3) |
| C++ | [`cpp/s/suffix_array_sais.cpp`](../../../cpp/s/suffix_array_sais.cpp) |
| Elisa | [`elisa/s/suffix_array_sais.elisa`](../../../elisa/s/suffix_array_sais.elisa) |
| Mojo | [`mojo/s/suffix_array_sais.mojo`](../../../mojo/s/suffix_array_sais.mojo) |
| Nim | [`nim/s/suffix_array_sais.nim`](../../../nim/s/suffix_array_sais.nim) |
| Odin | [`odin/s/suffix_array_sais.odin`](../../../odin/s/suffix_array_sais.odin) |
| Rust | [`rust/s/suffix_array_sais.rs`](../../../rust/s/suffix_array_sais.rs) |
| V | [`v/s/suffix_array_sais.v`](../../../v/s/suffix_array_sais.v) |
| Zig | [`zig/s/suffix_array_sais.zig`](../../../zig/s/suffix_array_sais.zig) |
