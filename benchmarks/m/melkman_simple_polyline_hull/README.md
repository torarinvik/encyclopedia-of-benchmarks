# Melkman simple-polyline convex hull

This in-progress benchmark constructs the convex hull of the vertices of a
simple polygonal chain in input order using Melkman's online deque algorithm.
Unlike the existing polar-angle Graham scan and x-sorted monotone-chain
profiles, it does not sort the input and exploits the chain's simplicity.

## Contract

Input to `i64_array_bytes_output` is `[n,x0,y0,...,x(n-1),y(n-1)]`, with
`3 <= n <= 32` and integer coordinates in `[-1000,1000]`. The input promises
that the open polyline is simple, all vertices are distinct, and no three
vertices are collinear. These promises are not fully checked; a collinear
initial triple is rejected, as is a deque state that cannot be updated
safely. Malformed framing, counts, and coordinates return `-1`. A null input
returns `-1`.

Output is the hull vertex indices in counterclockwise order, rotated to start
at the lexicographically smallest `(x,y)` vertex, each as a little-endian
signed i64. The return value is the number of bytes. A null or insufficient
output returns `-2` without writes. The largest valid frame has 65 input words
and 256 output bytes; the parseable malformed-frame limit is 66 words.

The primary keeps a closed counterclockwise deque with the latest extreme at
both ends. A point strictly inside both terminal edges leaves the hull alone;
otherwise, remove non-left turns from both ends and insert the point at both
ends. Each point enters and leaves the deque at most once, giving O(n) time
and O(n) space under the promised input conditions. The reference oracle
uses a sorted monotone chain, an independent O(n log n) method. As with the
algorithm itself, the stated time excludes testing the geometric promise.

Source: A. A. Melkman, “On-line construction of the convex hull of a simple
polyline,” *Information Processing Letters* 25 (1987), 11–12, [author's
publication record](https://www.bgu.ac.il/en/researcher/avraham-melkman/publications/317593075/).
The algorithm description is used for discovery only; implementations and
fixtures are independently authored. Reference drafts, workload, and ten
language drafts are present.

| Language | Draft port |
| --- | --- |
| C | [C](../../../c/m/melkman_simple_polyline_hull.c) |
| C3 | [C3](../../../c3/m/melkman_simple_polyline_hull.c3) |
| C++ | [C++](../../../cpp/m/melkman_simple_polyline_hull.cpp) |
| Elisa | [Elisa](../../../elisa/m/melkman_simple_polyline_hull.elisa) |
| Mojo | [Mojo](../../../mojo/m/melkman_simple_polyline_hull.mojo) |
| Nim | [Nim](../../../nim/m/melkman_simple_polyline_hull.nim) |
| Odin | [Odin](../../../odin/m/melkman_simple_polyline_hull.odin) |
| Rust | [Rust](../../../rust/m/melkman_simple_polyline_hull.rs) |
| V | [V](../../../v/m/melkman_simple_polyline_hull.v) |
| Zig | [Zig](../../../zig/m/melkman_simple_polyline_hull.zig) |

The byte-output runner and verifier are wired to the package. The verifier
source includes both directions of bounded parabola chains and translated
copies, which satisfy the simple and general-position promises. Static review
is ongoing; nothing has been executed.
