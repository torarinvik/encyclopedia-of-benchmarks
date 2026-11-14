# Divide-and-conquer convex hull by tangent merging

This reserved candidate recursively divides points sorted by x into contiguous
halves. Each half produces upper and lower x-monotone hull chains. To merge two
upper chains, start at the right endpoint of the left chain and the left
endpoint of the right chain; move endpoints outward while a neighboring point
lies above the proposed bridge. Keep the left prefix and right suffix at the
common upper tangent. The lower chain uses the symmetric orientation rule.
Concatenating the lower chain with the reversed upper interior gives the hull.
With linear tangent walks and merging, sorting and construction take
O(n log n) time and O(n) auxiliary space.

The draft contract uses `[n,x0,y0,...]` as signed i64 values, `3 <= n <= 32`,
coordinates in `[-1000,1000]`, distinct x coordinates and no three collinear.
The exact valid length is `1+2*n`; 66 words is the maximum parseable length.
Output is little-endian i64 coordinate pairs in counterclockwise order from the
lexicographically least point, returning the byte count. Invalid or null input
returns `-1`; valid input with null or insufficient output returns `-2`; errors
write nothing. Output is at most 512 bytes. Explicit general-position
validation takes O(n³) time and is included in this bounded profile.

The chapter identifies divide-and-conquer hull construction; the independently
written algorithm follows the mathematical tangent-merging description in
[Mount's geometry notes](https://www.cs.umd.edu/class/spring2026/cmsc754/Lects/lect02-hulls-1.pdf).
The notes are used as an idea source only; no code, prose, or examples were
copied. Recursive tangent-merge and monotone-chain reference drafts, a workload,
and a rights note are present. An initial [C draft](../../../c/d/divide_conquer_tangent_hull.c)
uses disjoint output slices during recursive merging. Drafts in all ten languages,
a package checker, and byte-output runner/verifier wiring are present; none has
been run. The verifier source specifies convex chains reflected across the x
axis and reversed in input order, generated
general-position point sets, input-order permutations, malformed frames, and
output-capacity probes.
The workload includes triangles on both sides of their endpoint baseline, an
unsorted triangle with interior points, null output, invalid-input precedence,
and null input at the parser limit.
A [Rust draft](../../../rust/d/divide_conquer_tangent_hull.rs) uses owned
vectors internally and confines raw pointers to the ABI boundary. Both ports
remain uncompiled and untested.
A [C++ draft](../../../cpp/d/divide_conquer_tangent_hull.cpp) uses owned
containers for recursive chains and also remains uncompiled and untested.
An [Elisa draft](../../../elisa/d/divide_conquer_tangent_hull.elisa) uses
bounded views and fixed arrays internally, with ABI references at the boundary.
It also remains uncompiled and untested.
A [Nim draft](../../../nim/d/divide_conquer_tangent_hull.nim) uses sequences
for recursive chains and remains uncompiled and untested.
A [Zig draft](../../../zig/d/divide_conquer_tangent_hull.zig) uses fixed arrays
and recursive slices of its output buffers; it remains uncompiled and untested.
A [C3 draft](../../../c3/d/divide_conquer_tangent_hull.c3) also uses fixed
buffers and remains uncompiled and untested.
An [Odin draft](../../../odin/d/divide_conquer_tangent_hull.odin) uses fixed
arrays and slices and remains uncompiled and untested.
A [V draft](../../../v/d/divide_conquer_tangent_hull.v) uses dynamic arrays for
recursive chains and remains uncompiled and untested.
A [Mojo draft](../../../mojo/d/divide_conquer_tangent_hull.mojo) uses inline
arrays and remains uncompiled and untested.
