# DC3 suffix-array construction

This clean-room profile implements the Kärkkäinen–Sanders–Burkhardt DC3
difference-cover algorithm described in the chapter. It partitions suffix
starts by their index modulo three, recursively orders the residue-1/residue-2
sample through ranks of length-three substrings, sorts residue-0 suffixes by
their first symbol and next-sample rank, then merges the two orders using the
chapter's pair and triple comparisons. The reduced sequence concatenates the
residue-1 and residue-2 rank runs with a low separator between them. Symbol
zero is remapped to one so zero can serve as the smaller-than-alphabet padding
and run separator. Inputs of length at most three use a direct base case.

Input is `[text_length, byte_symbols...]`, with text length 0 through 16 and
symbols 0 through 255. The output is the suffix-start permutation encoded as
little-endian signed 64-bit integers. Empty text returns zero bytes. Malformed
input returns `-1`; a null output pointer or insufficient capacity returns
`-2` without writes. The small bound keeps the full recursive profile
bounded. Maximum output is 128 bytes and the recursive fixed-array workspace
is bounded to 8,192 bytes. This implementation uses insertion sorting for its
bounded triples and residue-0 list, so it makes no linear-time performance
claim for those finite arrays.

The primary oracle follows the DC3 sample recursion and merge. The independent
verifier sorts complete suffix slices directly. The existing
[`suffix_array`](../suffix_array/README.md) package implements rank doubling
(Manber–Myers) and is a distinct suffix-array construction algorithm.

Source: Juha Kärkkäinen, “Suffix Array Construction,” *Encyclopedia of
Algorithms*, DOI [`10.1007/978-1-4939-2864-4_412`](https://doi.org/10.1007/978-1-4939-2864-4_412).
The package contains no copied book text, figures, or code; see
[RIGHTS.md](RIGHTS.md).

## Workload and ports

The [workload](workload.json) covers empty and singleton input, repeated and
periodic symbols, an embedded zero byte, alphabet boundaries, a maximum-size
ascending text, malformed framing, null buffers, and output capacity.

| Language | Port |
| --- | --- |
| C | [`c/s/suffix_array_dc3.c`](../../../c/s/suffix_array_dc3.c) |
| C3 | [`c3/s/suffix_array_dc3.c3`](../../../c3/s/suffix_array_dc3.c3) |
| C++ | [`cpp/s/suffix_array_dc3.cpp`](../../../cpp/s/suffix_array_dc3.cpp) |
| Elisa | [`elisa/s/suffix_array_dc3.elisa`](../../../elisa/s/suffix_array_dc3.elisa) |
| Nim | [`nim/s/suffix_array_dc3.nim`](../../../nim/s/suffix_array_dc3.nim) |
| Odin | [`odin/s/suffix_array_dc3.odin`](../../../odin/s/suffix_array_dc3.odin) |
| Rust | [`rust/s/suffix_array_dc3.rs`](../../../rust/s/suffix_array_dc3.rs) |
| V | [`v/s/suffix_array_dc3.v`](../../../v/s/suffix_array_dc3.v) |
| Zig | [`zig/s/suffix_array_dc3.zig`](../../../zig/s/suffix_array_dc3.zig) |
