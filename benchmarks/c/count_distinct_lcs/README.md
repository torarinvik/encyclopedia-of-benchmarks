# Count distinct longest common subsequences

Return the number of distinct longest common subsequence strings of two byte
sequences, modulo 1,000,000,007. Input is `[n,m,A[0..n-1],B[0..m-1]]`,
where `0 <= n,m <= 64` and all symbols are `0..255`. Exact length is
`2+n+m`; up to 131 words are parseable. Invalid or null input returns `-1`.
The empty subsequence counts as one when the LCS length is zero. Different
embeddings of the same string count once.

For each pair of prefixes, track the LCS length and the number of distinct
strings of that length. Equal final symbols extend diagonal solutions. For
unequal symbols, add counts from the optimal upper and left cells, then
subtract their intersection when the diagonal has the same optimal length.
Rolling rows yield `O(n*m)` time and `O(m)` space. An independent small-input
oracle enumerates subsequence strings and compares sets.

[`longest_common_subsequence`](../../l/longest_common_subsequence/README.md)
finds a longest subsequence rather than the number of distinct optimum
strings; [`count_different_palindromic_subsequences`](../count_different_palindromic_subsequences/README.md)
counts palindromes from one sequence. Neither performs this two-string
duplicate-aware counting recurrence. [Greenberg's research note](https://arxiv.org/abs/cs/0301034)
describes distinct-LCS counting. Only mathematical ideas are used; contract,
code, and fixtures are independently authored.

Contract, reference models, ten language drafts, workload, rights note,
package checker, and scalar-suite wiring are drafted. Verifier source specifies
exhaustive small binary pairs and a full-size modular-count case. Nothing has
been compiled or executed; all drafts remain unverified.

Timed fixtures also include alternating 64-symbol inputs, which have two
distinct longest strings despite repeated embeddings, and both orientations
of a 64-symbol input paired with an empty sequence.
