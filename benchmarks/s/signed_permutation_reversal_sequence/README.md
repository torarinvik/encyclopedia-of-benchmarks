# Signed-Permutation Reversal Sequence

This bounded profile implements the chapter's O(n^4) self-reduction for
constructing a shortest sorting sequence by signed reversals from “Sorting
Signed Permutations by Reversal (Reversal Sequence),” Eric Tannier,
*Encyclopedia of Algorithms*, DOI 10.1007/978-1-4939-2864-4_384. A reversal
reverses an inclusive segment and flips every sign in it. The target is
`[1,2,...,n]`.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[n,p1,...,pn]`, where `2<=n<=5`
and the `pi` form a signed permutation containing exactly one of `+i` or `-i`
for each `i` in `1..n`. A source step tries reversals and selects one whose
reversal distance drops by one. The profile chooses the lexicographically
smallest one-based inclusive interval `(left,right)` among qualifying moves at
each step, fully specifying the chapter's otherwise open tie choice.

Output is a little-endian i64 vector `[move_count,left1,right1,...]` with
exactly one pair per move. The sequence is shortest and reaches the identity;
the output uses at most 21 i64 values (168 bytes). Invalid inputs return `-1`.
A null or too-small output buffer returns `-2` without writing output.

To keep all nine ports bounded, the distance subroutine is an exact breadth-
first search over the at most `5! * 2^5 = 3840` signed permutations. The primary
oracle searches from the supplied instance and retains a shortest-path
predecessor; the independent verifier builds the distance table from the
identity and then performs the source's distance-decreasing self-reduction.
This preserves the shortest-sequence behavior and tie rule, but does not claim
the chapter's O(n^4) running time or implement the separate Bader overlap-forest
distance algorithm from DOI 383.

## Files

Nine language ports live under `c/s`, `cpp/s`, `rust/s`, `c3/s`, `nim/s`,
`odin/s`, `elisa/s`, `v/s`, and `zig/s`. The workload and both Python oracles
define the bounded source profile.
