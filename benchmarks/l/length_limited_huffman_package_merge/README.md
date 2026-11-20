# Length-limited Huffman coding with package-merge

Package-merge constructs an optimal binary prefix code when every codeword is
limited to at most `L` bits. It solves the length constraint directly and is a
distinct profile from ordinary Huffman coding.

## Contract

- `i64_array_scalar` input is `[n,L,w_0,...,w_(n-1)]`.
- `2<=n<=12`, `1<=L<=6`, `n<=2^L`, and each weight is in `[0,1000000]`.
- The frame contains exactly `n+2` words. Return the minimum weighted code
  length `sum(w_i*length_i)`, or `-1` for invalid input.
- The maximum result is `72,000,000`.

## Deterministic profile

Create one item of weight `w_i` at each depth `1..L`, with width `2^-depth`.
Scale widths by `2^L`, making them powers of two, and set the target width to
`(n-1)*2^L`. Process item lists from the smallest width upward. If the current
width equals the smallest power-of-two term in the remaining target, select
the lightest item and subtract its width. Pair the remaining consecutive items
from lightest upward into packages of twice the width, discard an unpaired
heaviest item, and merge those packages into the next width list. The sum of
the selected item weights is the optimal length-limited weighted cost. The
implementation only needs package weights, not the reconstructed code tree.

The straightforward lists use `O(nL)` time and space. An independent oracle
enumerates feasible nondecreasing code-length vectors after sorting weights in
descending order.

## Source

- Lawrence L. Larmore and Daniel S. Hirschberg, [A Fast Algorithm for Optimal
  Length-Limited Huffman Codes](https://doi.org/10.1145/79147.79150), *Journal of
  the ACM* 37(3), 464–473 (1990).
