# Strange Printer II

The task asks whether a target color grid can be built when each color may be
printed once as an axis-aligned rectangle and later prints overwrite earlier
ones. This is distinct from local [Strange Printer](../strange_printer/README.md),
which minimizes the number of one-dimensional interval turns. Here the output
is feasibility, determined by rectangle-order constraints.

## Contract

The `i64_array_scalar` input is `[rows, columns, cells...]`, with cells in
row-major order and exactly `2 + rows*columns` signed 64-bit words. The bounded
profile accepts `1 <= rows, columns <= 6` and colors `1..6`; any subset of the
six colors may occur. A valid answer is `1` when the grid is printable and `0`
otherwise. Invalid framing, out-of-range dimensions or colors, and null input
return `-1`. The maximum valid frame has 38 words; up to 39 words are accepted
by the parser only to reject trailing input.

## Rectangle dependencies

For each color, compute the smallest rectangle containing all of its target
cells. If that rectangle contains a target cell of another color, the first
color must be printed earlier so the other color can overwrite that cell.
Add a directed edge from the containing color to the target cell's color,
deduplicating repeated constraints. A valid print order exists exactly when
this graph is acyclic. The timed port uses indegrees and Kahn's queue-based
topological elimination; the graph is bounded to six vertices and 36 cells.

The independent reference does not construct a dependency graph. It simulates
all permutations of the present colors, applying each color's bounding box to
a blank canvas, and checks whether any final canvas equals the target. With at
most six colors there are at most 720 orders. The primary topological-order
algorithm follows A. B. Kahn's 1962 method; the grid-specific reduction is a
clean-room derivation from the one-use overwrite rule.

## Sources and ports

Task identification: [LeetCode 1591, Strange Printer II](https://leetcode.com/problems/strange-printer-ii/).
Topological sorting: [Kahn, “Topological sorting of large networks”](https://doi.org/10.1145/368996.369025).
See [`RIGHTS.md`](RIGHTS.md) and [`INVENTORY.md`](INVENTORY.md).

| Language | Source |
| --- | --- |
| C | [`c/s/strange_printer_ii.c`](../../../c/s/strange_printer_ii.c) |
| C3 | [`c3/s/strange_printer_ii.c3`](../../../c3/s/strange_printer_ii.c3) |
| C++ | [`cpp/s/strange_printer_ii.cpp`](../../../cpp/s/strange_printer_ii.cpp) |
| Elisa | [`elisa/s/strange_printer_ii.elisa`](../../../elisa/s/strange_printer_ii.elisa) |
| Mojo | [`mojo/s/strange_printer_ii.mojo`](../../../mojo/s/strange_printer_ii.mojo) |
| Nim | [`nim/s/strange_printer_ii.nim`](../../../nim/s/strange_printer_ii.nim) |
| Odin | [`odin/s/strange_printer_ii.odin`](../../../odin/s/strange_printer_ii.odin) |
| Rust | [`rust/s/strange_printer_ii.rs`](../../../rust/s/strange_printer_ii.rs) |
| V | [`v/s/strange_printer_ii.v`](../../../v/s/strange_printer_ii.v) |
| Zig | [`zig/s/strange_printer_ii.zig`](../../../zig/s/strange_printer_ii.zig) |
