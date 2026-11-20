# Chan's output-sensitive planar convex hull

This benchmark uses Chan's grouped wrapping method, not a separate
alias for ordinary Jarvis march or monotone chain. For each guess `H`, partition
the input into groups of at most `H`, construct each group's convex hull, and
wrap the global hull by finding the appropriate tangent to each group hull.
If the wrap has not closed within `H` steps, rebuild with the next larger
guess. The paper's schedule grows `H` doubly exponentially, capped at the input
size. With logarithmic tangent searches, this gives O(n log h) time and O(n)
space for `h` hull vertices.

The ABI input is `[n,x0,y0,...]`, with `3 <= n <= 32`, coordinates in
`[-1000,1000]`, distinct points, and no three collinear. Exact length is
`1+2*n`; the maximum valid and parseable lengths are 65 and 66 words. Output
is the extreme hull vertices as counterclockwise little-endian signed i64
coordinate pairs, starting at the lexicographically least point. The return
value is the byte count. Invalid or null input returns `-1`; a valid input with
null or insufficient output returns `-2`. Errors write nothing. Output needs at
most 512 bytes. The native workspace cap is 16,384 bytes for point records,
packed subgroup hulls, group metadata, local sorting/hull buffers, wrap state,
and bounded call frames, excluding caller-owned input and output. The bounded
validation of general position takes O(n³) time; the O(n log h) bound above
describes the hull kernel, not validation.

The independent monotone-chain reference checks the output contract. A grouped
reference separately models subgroup construction, wrapping, and retry
scheduling with linear scans; it is a correctness aid, not a timed port or
evidence of logarithmic tangent search. An exhaustive supporting-vertex oracle
defines the tangent direction independently, including singleton and
two-point groups. The source-level reference checker specifies small
general-position sets, retries, input permutations, equal-x coordinates,
maximum-size convex chains, output errors, and tangent queries across cyclic
polygon rotations. It has not been run.

The ten native ports group input points, build each subgroup hull, and wrap the
global hull with a binary tangent search. For an external query that is a
global hull vertex, all subgroup rays lie in an open half-plane. Their polar
angles form a rotated-sorted sequence in the subgroup's counterclockwise
order. Comparing the midpoint ray with the high-end ray by orientation lets the
search locate the minimum angle in logarithmic time. If the query belongs to
the current subgroup, its counterclockwise hull successor supplies that
group's candidate directly; singleton groups containing it contribute none.
This replaced an earlier anchor-based search whose branch choices were not
consistent with the orientation cases. Static review checked the search and
wrap structure across all ten ports; no programs, helpers, tests, builds, or
compilers have been run.

The [C port](../../../c/c/chan_output_sensitive_hull.c) stores subgroup hull
indices in one packed array with per-group offsets. The [Rust port](../../../rust/c/chan_output_sensitive_hull.rs)
uses owned vectors and confines raw pointers to its ABI boundary. The [C++ port](../../../cpp/c/chan_output_sensitive_hull.cpp)
uses owned containers. The [Elisa port](../../../elisa/c/chan_output_sensitive_hull.elisa)
uses bounded views and fixed arrays, keeping ABI references at the exported
boundary. The [Nim port](../../../nim/c/chan_output_sensitive_hull.nim) uses
sequences; [Zig](../../../zig/c/chan_output_sensitive_hull.zig),
[C3](../../../c3/c/chan_output_sensitive_hull.c3), and
[Odin](../../../odin/c/chan_output_sensitive_hull.odin) use fixed buffers;
[V](../../../v/c/chan_output_sensitive_hull.v) uses dynamic arrays; and
[Mojo](../../../mojo/c/chan_output_sensitive_hull.mojo) uses inline arrays.
All remain uncompiled and untested.

Byte-output runner and verifier registration and a static package inventory
checker are present. The verifier source specifies convex chains through the
32-point limit in both directions, generated general-position sets, and
output-capacity probes. The workload also records null output, invalid-input
precedence, null input at the parseable-length limit, and an unsorted case with
interior points. Suite code and static helpers remain unrun.

Source: Timothy M. Chan, [“Optimal Output-Sensitive Convex Hull Algorithms in
Two and Three Dimensions”](https://sites.cs.ucsb.edu/~suri/cs235/ChanCH.pdf)
(1996), planar algorithm. The published paper is copyrighted; only its
mathematical ideas are used. Implementations, contract, and fixtures are
independently written. No code or source prose has been copied, and no programs
have been run.
