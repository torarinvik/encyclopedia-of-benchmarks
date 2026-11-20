# LZ78RL binary run-length transform

This package implements the bounded LZ78RL composition described by Kosaraju
and Manzini: transform each maximal run into its binary length representation,
then apply greedy LZ78 to the transformed sequence. It is a clean-room
benchmark profile, not a compressor format interoperability claim.

## Contract

The exported symbol is `lz78_run_length_transform` with the
`i64_array_bytes_output` ABI. Input is `[n, symbol_0, ..., symbol_(n-1)]`,
where `0 <= n <= 32`, each source symbol is in `1..3`, and the exact frame
length is `n+1`. Code 0 is reserved for zeros in the run transform. The
maximum valid and parseable frame lengths are 33 and 34 words.

For each maximal run `alpha^m`, write `m` in ordinary binary, most-significant
bit first and without leading zeros. Emit `alpha` for each one bit and 0 for
each zero bit. For example, a run of five copies of symbol 2 becomes `[2,0,2]`.
Each transformed run is no longer than its source run, so the transformed
sequence has at most 32 symbols.

Apply greedy LZ78 to the transformed stream. Dictionary phrase ID 0 names the
empty phrase; each newly added phrase gets the next increasing ID. A normal
token is `(parent_phrase_id, next_symbol, 0)`. If the final nonempty suffix is
already a dictionary phrase, emit `(phrase_id, 0, 1)`. The third field marks
this terminal phrase, because 0 is a legal transformed symbol. Empty input
emits no phrase tokens.

Output is little-endian signed-i64 words:
`[token_count, (parent_id, next_symbol, terminal_tag)*]`. At most 32 tokens
are emitted, so the output is bounded by 776 bytes. A valid call returns the
number of bytes written. Malformed or null input returns `-1`; null output or
insufficient capacity returns `-2`. Input validation precedes output checks,
and error returns write no bytes. Even an empty valid input needs an 8-byte
output buffer for its zero token count.

The primary reference builds the run transform and parses with a four-way
phrase trie. The independent reference groups runs into a materialized tuple
and uses full phrase tuples with direct membership probes. The bounded ports
use O(n) space and O(n) operations for the transform and trie parser; the
independent phrase-set reference uses O(n^2) total symbol comparisons in the
worst case. Neither profile makes a production-scale runtime claim. The
paper proves a 3-optimality bound for its source coding model; this benchmark
serializes parse tokens as signed-i64 records and does not evaluate the
encoded-bit-length bound.

## Provenance and rights

The primary source is Kosaraju and Manzini, “Compression of Low Entropy
Strings with Lempel–Ziv Algorithms,” §3.1, [DOI
10.1137/S0097539797331105](https://doi.org/10.1137/S0097539797331105). The
algorithm is also listed in Simon J. Puglisi, [“Lempel-Ziv Compression,”
Encyclopedia of Algorithms, DOI
10.1007/978-1-4939-2864-4_634](https://doi.org/10.1007/978-1-4939-2864-4_634).
These works are cited for attribution and algorithm ideas only. The package
contains clean-room implementations and does not copy source code, figures,
or extended prose. See [RIGHTS.md](RIGHTS.md).

## References and workload

- [Primary trie reference](primary_oracle.py)
- [Independent phrase-set reference](independent_oracle.py)
- [Bounded workload](workload.json)
- [Static package inventory](verify_workload.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/l/lz78_run_length_transform.c`](../../../c/l/lz78_run_length_transform.c) |
| C3 | [`c3/l/lz78_run_length_transform.c3`](../../../c3/l/lz78_run_length_transform.c3) |
| C++ | [`cpp/l/lz78_run_length_transform.cpp`](../../../cpp/l/lz78_run_length_transform.cpp) |
| Elisa | [`elisa/l/lz78_run_length_transform.elisa`](../../../elisa/l/lz78_run_length_transform.elisa) |
| Mojo | [`mojo/l/lz78_run_length_transform.mojo`](../../../mojo/l/lz78_run_length_transform.mojo) |
| Nim | [`nim/l/lz78_run_length_transform.nim`](../../../nim/l/lz78_run_length_transform.nim) |
| Odin | [`odin/l/lz78_run_length_transform.odin`](../../../odin/l/lz78_run_length_transform.odin) |
| Rust | [`rust/l/lz78_run_length_transform.rs`](../../../rust/l/lz78_run_length_transform.rs) |
| V | [`v/l/lz78_run_length_transform.v`](../../../v/l/lz78_run_length_transform.v) |
| Zig | [`zig/l/lz78_run_length_transform.zig`](../../../zig/l/lz78_run_length_transform.zig) |
