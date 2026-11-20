# Multiword bit-vector edit distance

Compute the unit-cost Levenshtein distance between two byte sequences using
Myers's bit-vector dynamic programming. Input is [n,m,A...,B...] with lengths
in 0..256, bytes in 0..255, and exactly 2+n+m signed i64 words. Null or
malformed input returns -1; the result for valid input is in 0..256.

Position masks encode the first sequence. Positive and negative vertical
differences are updated for each byte of the second sequence using bitwise
operations and addition with carry across 64-bit words. Horizontal difference
vectors are shifted across word boundaries. The score tracks the bottom row.
The empty first sequence is handled directly. At word width 64, time is
O(n + 256*ceil(n/64) + m*ceil(n/64)) and storage is O(256*ceil(n/64)).

The existing scalar Levenshtein profile uses ordinary dynamic programming,
the run-length profile operates on compressed runs, and the approximate
substring benchmark permits free restarts. This profile instead computes the
global edit distance using word-parallel updates. [Myers (1999)](https://doi.org/10.1145/316542.316550)
describes the method; only mathematical ideas are used, with independent
contract and implementation. The paper is copyrighted; no paper text or code
is copied.

The contract, scalar reference, ten language drafts, workload, package
checker, and scalar-suite runner and verifier wiring are present. Fixtures
include lengths around each 64-bit boundary, insertions and deletions across a
word boundary, and full-size identical and disjoint cases.
The verifier specifies exhaustive small binary sequences and further boundary
cases. Nothing has been compiled or executed; validation remains outstanding.
