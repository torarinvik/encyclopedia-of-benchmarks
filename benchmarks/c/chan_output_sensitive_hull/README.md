# Chan's output-sensitive planar convex hull

This reserved candidate uses Chan's grouped wrapping method, not a separate
alias for ordinary Jarvis march or monotone chain. For each guess `H`, partition
the input into groups of at most `H`, construct each group's convex hull, and
wrap the global hull by finding the appropriate tangent to each group hull.
If the wrap has not closed within `H` steps, rebuild with the next larger
guess. The paper's schedule grows `H` doubly exponentially, capped at the input
size. With logarithmic tangent searches, this gives O(n log h) time and O(n)
space for `h` hull vertices.

The proposed ABI input is `[n,x0,y0,...]`, with `3 <= n <= 32`, coordinates in
`[-1000,1000]`, distinct points, and no three collinear. Exact length is
`1+2*n`; the maximum valid and parseable lengths are 65 and 66 words. Output
is the extreme hull vertices as counterclockwise little-endian signed i64
coordinate pairs, starting at the lexicographically least point. The return
value is the byte count. Invalid or null input returns `-1`; a valid input with
null or insufficient output returns `-2`. Errors write nothing. Output needs at
most 512 bytes. The bounded validation of general position takes O(n³) time;
the O(n log h) bound above describes the hull kernel, not validation.

This benchmark is a draft and has not been validated. In particular, a linear
scan of every group hull would not provide the stated output-sensitive
tangent-search algorithm. A separately written
monotone-chain reference and initial fixtures record the output contract.
The grouped reference additionally models group construction, wrapping, and
retry scheduling using linear scans. It is a correctness aid, not a timed port
or evidence of logarithmic tangent search.
The draft reference checker specifies fixture comparisons, small general-position
sets, and all permutations of a five-vertex hull that must retry after the first
four-step guess. It also specifies permutations of a triangular hull with two
interior points, a quadrilateral with equal x coordinates, maximum-size convex chains in both orders,
short-output handling, and invalid-input precedence. It has not been run.
An additional exhaustive supporting-vertex oracle defines the desired tangent
direction for future binary-search comparisons, including a singleton containing
the query. Its draft cases also cover two-point groups and external queries on
different polygon sides, with cyclic rotations of polygon storage. It is
quadratic and is not a benchmark implementation.

An incomplete [C draft](../../../c/c/chan_output_sensitive_hull.c) implements
bounded validation, mergesort-based subgroup hulls, the wrapping/retry structure,
output encoding, and an exported ABI function. An initial logarithmic tangent
search draft uses orientation signs and the angle order induced by the global
supporting half-plane; its invariants and edge cases require static review and
it has not been compiled or run. The remaining language ports and suite
registration are described below.
The C draft stores all subgroup hull indices in one packed array, whose total
length is at most `n`, with per-group offsets and lengths. A [Rust draft](../../../rust/c/chan_output_sensitive_hull.rs)
uses owned vectors and confines raw pointers to its exported ABI. Both drafts
share the unverified tangent-search decisions; neither has been compiled or run.
A [C++ draft](../../../cpp/c/chan_output_sensitive_hull.cpp) also uses owned
containers and remains uncompiled and untested.
The [Elisa draft](../../../elisa/c/chan_output_sensitive_hull.elisa) uses
bounded input and output views and fixed arrays; ABI references remain at the
exported boundary. It shares the unverified tangent-search method.
A [Nim draft](../../../nim/c/chan_output_sensitive_hull.nim) uses sequences
internally and remains uncompiled and untested.
A [Zig draft](../../../zig/c/chan_output_sensitive_hull.zig) uses fixed arrays
and remains uncompiled and untested.
A [C3 draft](../../../c3/c/chan_output_sensitive_hull.c3) uses fixed arrays and
remains uncompiled and untested.
An [Odin draft](../../../odin/c/chan_output_sensitive_hull.odin) uses fixed
arrays and slices internally and remains uncompiled and untested.
A [V draft](../../../v/c/chan_output_sensitive_hull.v) uses dynamic arrays and
remains uncompiled and untested.
A [Mojo draft](../../../mojo/c/chan_output_sensitive_hull.mojo) uses inline
arrays and remains uncompiled and untested.

Draft byte-output runner and verifier registration and a package inventory
checker are present. The verifier source includes convex chains up to the
32-point limit in both directions, generated general-position point sets, and
output-capacity probes. No suite code has
been run, and the shared tangent-search method remains unverified.
The workload also records null output, invalid-input precedence, and null
input at the parseable-length limit. An unsorted fixture contains interior
points and supplies a triangle's canonical coordinate output.

A separate Python draft spells out the same binary-search decisions. The
reference checker specifies comparisons against the exhaustive tangent oracle
for small convex subgroups, external global-hull vertices, and every cyclic
rotation; these comparisons have not been run.

For an external query that is a global extreme point, the subgroup rays fit
inside a half-plane, so orientation orders their directions without a circular
angle discontinuity. Along a strictly convex subgroup boundary this direction
increases along one arc and decreases along the other. The tangent draft seeks
the angular minimum: if the first edge increases, an increasing midpoint below
the first ray lies after the minimum, while all other non-minimum midpoint cases
lie before it. If the first edge decreases, an increasing midpoint or a
decreasing midpoint above the first ray lies after the minimum; otherwise it
lies before it. Neighbor comparisons identify the minimum itself. This is the
draft's intended search invariant, not a completed correctness proof.

The [KIT geometry notes](https://i11www.iti.kit.edu/_media/teaching/sommer2018/compgeom/psession1.pdf)
describe logarithmic tangent search for an external query point. A group may
also contain the current hull vertex, so the eventual implementation must
explicitly handle this boundary case as well as one- and two-point groups.
Under this profile's no-three-collinear rule, when the current global hull
vertex belongs to a group's hull, its counterclockwise successor on that group
hull is the candidate for the global counterclockwise wrapping step. Keeping a
point-to-group-hull index during construction allows that case to be resolved
without a linear search. The external-point binary-search draft still needs
full static review.

Source: Timothy M. Chan, [“Optimal Output-Sensitive Convex Hull Algorithms in
Two and Three Dimensions”](https://sites.cs.ucsb.edu/~suri/cs235/ChanCH.pdf)
(1996), planar algorithm. The published paper is copyrighted; only its
mathematical ideas are used. Implementations, contract, and fixtures will be
independently written. No code or source prose has been copied, and no programs
have been run.
