# Trie with autocomplete and frequency search

This benchmark follows the pinned C++ trie operations for insertion, exact
presence checks, autocomplete, and frequency-ranked autocomplete. It is distinct
from the basic [`trie`](../trie/README.md) benchmark. The defective delete path
is excluded.

## Contract

The `i64_array_scalar` input is
`[operation_count, (opcode, word_length, ascii_code...)*]`. The operation count
is 0..64, inserted words are 1..32 ASCII letters, search keys are 0..32 ASCII
letters, and at most 32 distinct words may be inserted. Both uppercase and
lowercase ASCII are accepted; the source compares letters case-insensitively
and stores/prints autocomplete completions in lowercase. Empty search keys are
supported, but inserting an empty word is outside this bounded domain. A valid maximum input has
2,177 signed 64-bit words; one additional word is parseable to reject trailing
input.

| Opcode | Operation | Effect |
|---:|---|---|
| 0 | `insert(word)` | Inserts the case-folded word; duplicates leave its frequency unchanged. The source operation is void. |
| 1 | `search-presence(word)` | Returns 1 for a stored complete word, otherwise 0. A hit increments its frequency. |
| 2 | `autocomplete(key)` | Returns the exact key first if present, then all complete words below the longest matching trie path in lexicographic order. An exact-key hit increments its frequency. |
| 3 | `frequency-suggestions(key)` | Returns the exact key first if present, then up to three descendants ranked by `(frequency, word)` descending. An exact-key hit increments its frequency. |

Autocomplete and frequency search follow the source's path traversal. If the
whole key path exists, an exact stored key is emitted first and then strict
descendants are searched. If a key stops matching partway through, suggestions
come from the deepest node reached and exclude that node's own word, even when
it is terminal. Exact-key output preserves the query's original ASCII case, as
the source prints the key argument; generated words are lowercase. Suggestions
themselves do not increment frequencies. Frequency
ties are broken by reverse lexicographic word order, matching the source's
max-priority-queue of `(frequency, word)` pairs. At most 32 words are returned
by autocomplete and at most four by frequency search (the exact key plus three
descendants).

The scalar result is the low 63 bits of FNV-1a-64 over this byte stream:

1. Operation count as u16 little-endian.
2. For every operation, its opcode as u8. Insert has no result payload;
   presence appends the result as u8; autocomplete and frequency search append
   result count as u16 followed by each word as u8 byte length and ASCII bytes.
3. Final distinct-word count as u16, then each lowercase word in lexicographic
   order as u8 byte length, ASCII bytes, and its search frequency as u32
   little-endian.

The FNV offset basis is `14695981039346656037` and the prime is
`1099511628211`. Unknown opcodes, including delete, malformed records,
non-letter bytes, empty inserted words, words longer than 32, more than 32
distinct inserted words, or trailing input return `-1`.

The independent oracle models the dictionary directly and applies the source's
frequency and suggestion ordering rules. The workload includes case folding,
empty keys, longest-prefix fallback, exact matches, ranked ties, and malformed
inputs.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `trie_multiple_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/trie_multiple_search.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `trie_multiple_search.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/trie_multiple_search.cpp)

| Language | Port |
|---|---|
| C | [`c/t/trie_multiple_search.c`](../../../c/t/trie_multiple_search.c) |
| C3 | [`c3/t/trie_multiple_search.c3`](../../../c3/t/trie_multiple_search.c3) |
| C++ | [`cpp/t/trie_multiple_search.cpp`](../../../cpp/t/trie_multiple_search.cpp) |
| Elisa | [`elisa/t/trie_multiple_search.elisa`](../../../elisa/t/trie_multiple_search.elisa) |
| Nim | [`nim/t/trie_multiple_search.nim`](../../../nim/t/trie_multiple_search.nim) |
| Odin | [`odin/t/trie_multiple_search.odin`](../../../odin/t/trie_multiple_search.odin) |
| Rust | [`rust/t/trie_multiple_search.rs`](../../../rust/t/trie_multiple_search.rs) |
| V | [`v/t/trie_multiple_search.v`](../../../v/t/trie_multiple_search.v) |
| Zig | [`zig/t/trie_multiple_search.zig`](../../../zig/t/trie_multiple_search.zig) |
