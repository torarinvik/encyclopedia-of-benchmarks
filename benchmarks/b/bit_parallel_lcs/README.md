# Bit-parallel longest common subsequence length

Return the length of a longest common subsequence of two byte sequences.
Input is `[n,m,A[0..n-1],B[0..m-1]]`, where `0 <= n,m <= 256` and each
symbol is `0..255`. Exact length is `2+n+m`; at most 515 words are
parseable. Invalid or null input returns `-1`. Empty sequences return zero.

Build one position bit vector for each byte of `A`. For each byte of `B`,
combine its mask with the current bit-vector row, then use a shifted row and
multiword subtraction to find the row's new set bits. The number of set bits
in the final row is the LCS length. Carry from the shift and borrow from the
subtraction cross 64-bit word boundaries. This bounded implementation uses
`O(m*ceil(n/64) + n + 256*ceil(n/64))` time and
`O(256*ceil(n/64))` space; it returns a length, not an LCS witness.

[`longest_common_subsequence`](../../l/longest_common_subsequence/README.md)
uses scalar dynamic programming, [`hirschberg_lcs`](../../h/hirschberg_lcs/README.md)
uses linear-space divide and conquer, and [`hunt_szymanski_lcs`](../../h/hunt_szymanski_lcs/README.md)
uses match-position lists. Their methods differ from word-parallel row updates.
[Allison and Dix's paper](https://www.cantab.net/users/mmlist/ll/Publications/1986IPL/)
describes the bit-string method. Only the mathematical idea is used; the
contract, references, implementation, and fixtures are independently authored.

Contract, references, ten language drafts, workload, rights note, package
checker, and scalar-suite wiring are drafted. The verifier specifies exhaustive
small binary sequences, multiword boundaries, and maximum-size frames. No
programs or checks have been executed; all drafts remain unverified.
The workload includes matches at positions 64, 128, and 192 after empty low
words, forcing subtraction borrow across one, two, and three word boundaries.
