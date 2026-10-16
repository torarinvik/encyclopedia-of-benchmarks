# BM25 inverted-index ranking

This benchmark measures construction of the bounded postings for one query followed by BM25 ranking. The source is the pinned Java [`BM25InvertedIndex`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/BM25InvertedIndex.java), which indexes words from each movie name and content and ranks matching documents.

## Input and output

The input is a signed 64-bit array:

`[document_count, document_id, term_count, term..., ..., query_term]`

There are 0..32 documents. IDs are unique bytes in 0..255. Each document has 0..64 terms, with term IDs 1..255. Terms stand for already-normalized tokens, so tokenization and locale-specific lowercasing are outside this ranking benchmark. The ports collect the selected term frequency for each document in one pass, which is the query-specific column of the source inverted index. The final value is the query term ID. The full input is at most 2,114 values.

The function returns the number of matching documents and writes their IDs as bytes, in descending BM25 score order. Scores use the source constants `k1=1.5` and `b=0.75`; ties are ordered by ascending document ID so results are deterministic across runtimes. A missing query term returns zero and writes no bytes. Malformed input or insufficient output capacity returns `-2`.

For one query, inverse document frequency is common to every matching document and is positive under the source formula, so ranking is exactly determined by the term-frequency and document-length factor. The ports compare that factor as an exact rational value; they do not call platform `log` functions or depend on floating-point ranking near ties. The Java source uses a hash map whose iteration order does not define tied results, hence the explicit ID tie-break.

## Workloads

The workload covers an empty index, absent and present terms, repeated terms, document-length normalization, exact score ties, empty documents, a full-size index, malformed arrays, and output-capacity failure.
