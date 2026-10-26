# Parameterized pattern matching

This bounded profile searches a sequence of parameter symbols for every
substring that matches the pattern under a one-to-one renaming of symbols.
It uses the chapter's predecessor-string characterization: at each position,
encode `0` for a symbol's first occurrence in the current string and otherwise
the distance to its preceding occurrence. A window matches exactly when its
predecessor encoding equals the pattern encoding.

The selected profile uses only parameter symbols, one-dimensional exact
matching, and a fixed alphabet of 16 IDs. Input is
`[text_length, pattern_length, text_symbols..., pattern_symbols...]`, with
`0 <= text_length <= 24`, `1 <= pattern_length <= 8`, and symbols in `0..15`.
A pattern longer than the text is valid and returns no positions. Output is
`[match_count, start_0, ...]` as little-endian signed 64-bit values, with
zero-based starts in ascending order. The maximum output is 200 bytes. Invalid
input returns `-1`; a null output or insufficient capacity returns `-2`
without writing.

The primary oracle compares predecessor encodings independently for each
window. The verifier instead checks whether each window and pattern admit a
consistent one-to-one symbol map. These are separate formulations of the
chapter's equivalence. The profile does not implement approximate matching,
two-dimensional matching, suffix-tree indexing, or alphabet-dependent
parameterized suffix-tree construction.

Source: “Parameterized Pattern Matching,” Moshe Lewenstein, *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_282`](https://doi.org/10.1007/978-1-4939-2864-4_282).
The chapter identifies predecessor strings as a canonical representation for
parameterized matches. This package is clean-room and includes no book prose,
figures, or code. It is distinct from literal [`pattern_matching`](../pattern_matching/README.md):
different symbol IDs may match when the equality/repetition structure is the
same.

## Workload and implementations

The [workload](workload.json) covers renaming, repeated-symbol structure,
overlapping matches, maximum text/output, maximum packed input, empty text, a
pattern longer than the text, malformed framing and symbols, null buffers,
and short capacity.
The primary oracle is
[`parameterized_pattern_matching_oracle.py`](../../parameterized_pattern_matching_oracle.py);
the independent verifier is
[`parameterized_pattern_matching_verifier_oracle.py`](../../parameterized_pattern_matching_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/p/parameterized_pattern_matching.c` |
| C3 | `c3/p/parameterized_pattern_matching.c3` |
| C++ | `cpp/p/parameterized_pattern_matching.cpp` |
| Elisa | `elisa/p/parameterized_pattern_matching.elisa` |
| Nim | `nim/p/parameterized_pattern_matching.nim` |
| Odin | `odin/p/parameterized_pattern_matching.odin` |
| Rust | `rust/p/parameterized_pattern_matching.rs` |
| V | `v/p/parameterized_pattern_matching.v` |
| Zig | `zig/p/parameterized_pattern_matching.zig` |
