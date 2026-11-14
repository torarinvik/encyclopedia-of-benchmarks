# Subsequence automaton

Build a next-occurrence transition table for one sequence and use it to answer
multiple subsequence queries. This is a different computational method from
[`is_subsequence`](../../i/is_subsequence/README.md) and
[`validate_subsequence`](../../v/validate_subsequence/README.md), which scan
the main sequence for one query. The [OI Wiki sequence automaton](https://oi-wiki.org/string/seq-automaton/)
describes the transition-table construction; only the algorithm idea is used.

The `i64_array_scalar` input is `[n,q,text...,len_1,query_1...,...]`.
`0<=n<=64`, `0<=q<=32`, all symbols are in `0..3`, and the sum of query
lengths is at most 256. The frame must be exact. Return the sum of one-based
query indices whose queries are subsequences; empty queries match. Return `-1`
for malformed input or null input. The maximum valid frame has 354 words;
the runner accepts 355 words to cover an extra-word rejection, and the maximum
result is 528.

Build the table backwards with one row per text position and alphabet symbol,
then advance once per query symbol. The target complexity is O(4n+L+q) time
and O(4n) space, where L is the total query length. The references, contract,
and workload are independently written; no source code or examples are copied.
The workload includes repeated queries against a shared text so the transition
table is used across the batch. It also covers advancing exactly to the end of
the text and rejecting malformed lengths and symbols after an earlier miss.

Reserved for root. Drafts in all ten languages, the workload, references, and
scalar-suite registration are unverified. Nothing has been compiled or run.
