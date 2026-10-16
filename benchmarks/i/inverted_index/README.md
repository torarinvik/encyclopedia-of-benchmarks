# Inverted Index

This package ports the pinned C# inverted index for exact, case-sensitive space-delimited tokens. Each numeric document ID maps to the source name `doc<ID>`, and each numeric word ID maps to the token `w<ID>`. A document's words are joined with one ASCII space before indexing. Duplicate words within one document are removed, matching the source's `Distinct()` call.

## Contract

- The `i64_array_scalar` input is `[doc_count, (doc_id, word_count, word_id_0, ..., word_id_(word_count-1))*doc_count, operation, term_count, term_id_0, ..., term_id_(term_count-1)]` with exact length.
- `doc_count` is `0..256`; document IDs are unique values in `0..255`; each document has `1..256` word IDs and the total word-ID count is at most 4,096. Word and query-term IDs are in `0..65,535`.
- `operation == 0` performs AND (a document must contain every query term); `operation == 1` performs OR (a document must contain at least one query term). Queries contain `1..16` terms. Duplicate document words and duplicate query terms are allowed. A term absent from the index matches no documents.
- Empty documents/content and empty queries are outside the domain. Invalid operation, malformed length, duplicate/out-of-range document IDs, invalid counts, or out-of-range word IDs returns `-1`.
- Matching document IDs are sorted ascending. The scalar result is the low 63 bits of FNV-1a-64 over `[result_count, sorted_doc_ids...]` encoded as signed-i64 little-endian words. The offset basis is `14695981039346656037` and the prime is `1099511628211`.

The [independent oracle](../../inverted_index_oracle.py) uses sets for membership and query evaluation; the language ports build sparse per-word posting lists. The [workload](workload.json) covers empty-index queries, AND/OR behavior, duplicate words/terms, absent terms, ordering, boundary IDs, and invalid inputs.

## Upstream source

- [TheAlgorithms/C-Sharp `InvertedIndex.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/InvertedIndex.cs)

| Language | Port |
|---|---|
| C | [`c/i/inverted_index.c`](../../../c/i/inverted_index.c) |
| C3 | [`c3/i/inverted_index.c3`](../../../c3/i/inverted_index.c3) |
| C++ | [`cpp/i/inverted_index.cpp`](../../../cpp/i/inverted_index.cpp) |
| Elisa | [`elisa/i/inverted_index.elisa`](../../../elisa/i/inverted_index.elisa) |
| Nim | [`nim/i/inverted_index.nim`](../../../nim/i/inverted_index.nim) |
| Odin | [`odin/i/inverted_index.odin`](../../../odin/i/inverted_index.odin) |
| Rust | [`rust/i/inverted_index.rs`](../../../rust/i/inverted_index.rs) |
| V | [`v/i/inverted_index.v`](../../../v/i/inverted_index.v) |
| Zig | [`zig/i/inverted_index.zig`](../../../zig/i/inverted_index.zig) |
