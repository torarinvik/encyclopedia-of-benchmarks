# Flexible one-lookahead LZ78 parsing

This package covers the one-step lookahead parsing rule described in the
chapter's “Greedy vs. Non-Greedy Parsing” section. It is distinct from the
ordinary greedy LZ78 parser in [`lz78`](../lz78/README.md): the parser may
select a shorter current dictionary phrase when that makes the next greedy
dictionary match reach farther.

## Contract

ABI: `i64_array_bytes_output`; symbol: `lz78_flexible_parsing`.

Input is `[n, character_0, ..., character_(n-1)]`, where `0 <= n <= 32` and
each character is printable ASCII in `[32,126]`. The exact input length is
`n+1` words. The maximum valid input is 33 words; a 34-word parseable frame is
used to check rejection of trailing input.

The dictionary starts with the empty phrase at ID 0. At a text position, each
dictionary phrase `p` that matches the suffix and has a following character
`c` defines a candidate phrase `p+c`. For the trial dictionary, add `p+c` if
it is not already present. Let `L` be the length of the longest phrase in that
trial dictionary matching immediately after the candidate. Choose the
candidate maximizing the cumulative endpoint
`position + length(p+c) + L`. Ties choose the longer current phrase and then
the smaller parent dictionary ID. Emit `(parent_id,c)`, add a new phrase in
creation order, and advance by the current phrase length. This explicit tie
rule is a deterministic profile refinement; the chapter states the
advancement objective without specifying all ties.

If the remaining suffix is already a nonempty dictionary phrase, emit
`(phrase_id,0)` as the terminal token, matching the local LZ78 framing. Empty
input emits no tokens. The output is a sequence of little-endian signed-i64
pairs `(parent_id, character_code)` with no count prefix. At most 32 tokens
are emitted, so output is bounded by 512 bytes. The bounded implementation
uses explicit phrase arrays and does not claim the chapter's asymptotic
running-time result.

Malformed framing, unsupported length, or a character outside printable ASCII
returns `-1` before output checks. A null output pointer or insufficient
capacity returns `-2` after input validation. Errors write no bytes. A valid
empty input returns 0 with a nonnull output buffer, including zero capacity.
The declared 4096-byte workspace covers the phrase tables and staged output.

The `aabaaba` fixture demonstrates the non-greedy choice: after the initial
`a`, the lookahead parser selects `ab`, and later emits `a` followed by the
already known `ab`; ordinary greedy LZ78 instead selects `aa` at that later
position. Both token streams reconstruct the input, but the parse decisions
differ.

## Source and rights

Travis Gagie and Giovanni Manzini, “Dictionary-Based Data Compression,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_108`](https://doi.org/10.1007/978-1-4939-2864-4_108),
“Greedy vs. Non-Greedy Parsing.” The section attributes the one-step
lookahead method to Y. Matias and C. Sahinalp, “On the Optimality of Parsing
in Dynamic Dictionary Based Data Compression,” SODA 1999, pp. 943–944.

The chapter and cited paper are copyrighted; no source-code license is
asserted. These ports are clean-room implementations of the bounded parsing
contract and contain no copied source code or extended book prose. See
[`RIGHTS.md`](RIGHTS.md).

Primary and independent verifier oracles:
[`lz78_flexible_parsing_oracle.py`](../../lz78_flexible_parsing_oracle.py) and
[`lz78_flexible_parsing_verifier_oracle.py`](../../lz78_flexible_parsing_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/l/lz78_flexible_parsing.c`](../../../c/l/lz78_flexible_parsing.c) |
| C3 | [`c3/l/lz78_flexible_parsing.c3`](../../../c3/l/lz78_flexible_parsing.c3) |
| C++ | [`cpp/l/lz78_flexible_parsing.cpp`](../../../cpp/l/lz78_flexible_parsing.cpp) |
| Elisa | [`elisa/l/lz78_flexible_parsing.elisa`](../../../elisa/l/lz78_flexible_parsing.elisa) |
| Nim | [`nim/l/lz78_flexible_parsing.nim`](../../../nim/l/lz78_flexible_parsing.nim) |
| Odin | [`odin/l/lz78_flexible_parsing.odin`](../../../odin/l/lz78_flexible_parsing.odin) |
| Rust | [`rust/l/lz78_flexible_parsing.rs`](../../../rust/l/lz78_flexible_parsing.rs) |
| V | [`v/l/lz78_flexible_parsing.v`](../../../v/l/lz78_flexible_parsing.v) |
| Zig | [`zig/l/lz78_flexible_parsing.zig`](../../../zig/l/lz78_flexible_parsing.zig) |
