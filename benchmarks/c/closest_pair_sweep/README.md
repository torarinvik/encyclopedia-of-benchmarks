# Closest pair by plane sweep

This draft sorts planar points by x and sweeps from left to right. The active
set holds earlier points ordered by y; points whose x-distance already exceeds
the best known distance are removed. A y-range query finds candidates that can
improve the current squared Euclidean distance. Exact integer square root and
integer squared distances avoid floating-point boundary decisions. A sorted
duplicate-coordinate check returns zero before the sweep, keeping active points
distinct. Unlike [`closest_pair_divide_and_conquer`](../closest_pair_divide_and_conquer/README.md),
the algorithm maintains one dynamic active set instead of merging recursive
subproblems.

The scalar input is `[N,x0,y0,...,x(N-1),y(N-1)]`, with `2<=N<=64`, coordinates
in `[-1000,1000]`, and duplicates allowed. Exact length is `1+2*N`, at most 129
words; 130 is the parseable malformed-frame bound. Return the smallest squared
distance, in `0..8000000`, or `-1` for invalid or null input.

The intended timed ports use an ordered balanced tree for active points. The
C, C3, Elisa, Odin, V, and Mojo drafts use AVL trees and merge sort; Nim and Zig use AVL trees
with their standard sorts, and C++ and Rust use their ordered sets.
Their sort, insertions, deletions and y-range queries take `O(N log N)` time
and `O(N)` space. Distinct active points within the
bounded candidate square have a constant packing bound. The Python sweep
reference uses an ordered list and therefore has `O(N²)` worst-case time; the
independent reference enumerates all pairs.

The [Tulane sweep-line lecture](https://www.cs.tulane.edu/~carola/teaching/cs6463/fall10/slides/sweepline.pdf)
is used for the algorithmic idea only; no source text or code is copied. The
contract and drafts are independently authored. Ten language drafts, two
references, workload, rights note, package checker, and scalar suite wiring are
present. The workload includes a maximum-length horizontal point set; the
verifier source specifies small grids, input reversal, a maximum parabola, and
null input. Nothing has been compiled or run.
