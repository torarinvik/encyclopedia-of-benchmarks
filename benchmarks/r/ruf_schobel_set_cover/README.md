# Ruf–Schöbel branch-and-bound for almost-C1P set cover

This package profiles the branch-and-bound method of Ruf and Schöbel for
weighted set cover. It decomposes every row into maximal consecutive blocks,
relaxes each search node to an interval set-cover instance, and branches by
fixing one block for an unassigned multi-block row. Its lower bound is the
minimum cost of covering the node's interval rows. Its upper bound extends
that cover by choosing a cheapest block for each original row it still misses.
With epsilon fixed to zero, the bounded profile searches until it certifies
the exact minimum cost.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[row_count,column_count,weight_0,...,weight_(column_count-1),row_mask_0,...,row_mask_(row_count-1)]`.
There are 1–6 rows and 1–8 columns. Column weights are integers in 1..20;
bit `j` of a row mask means column `j` covers that row. A zero row is a valid
but uncoverable instance. The exact valid input length is
`2 + row_count + column_count`, at most 16 words; 17 words are accepted by
the parser solely to detect trailing input.

Success emits one little-endian signed i64 containing the minimum total weight.
A valid uncoverable instance emits `[-1]`. Malformed input returns `-1`;
null or undersized output returns `-2` without writes. The maximum output is
8 bytes.

The primary reference and all ports use the block-choice search from the
paper. Each C1P subproblem is solved exactly by a shortest-path dynamic program
over selected column positions; this bounded subsolver replaces the paper's
adapted network-simplex implementation. Optional domination preprocessing
and dual-simplex pivot strengthening are omitted. Branching is deterministic:
choose the first unassigned multi-block row, then visit its blocks left to
right. The independent reference enumerates all column subsets directly.
At most four blocks can occur in one eight-column row, so the depth-first
frontier holds at most `1 + 3*6 = 19` pending branch states; ports reserve
32 states. The documented 16 KiB workspace conservatively covers those
states, block endpoints, interval-DP arrays, call frames, and the staged result.

This is distinct from [`almost_c1p_set_cover_enumeration`](../almost_c1p_set_cover_enumeration/README.md),
which enumerates feasible partial covers row by row. It also differs from
[`set_cover_domination_reduction`](../set_cover_domination_reduction/README.md),
which performs presolve reductions but does not solve the instance, and
[`gbbs_approximate_set_cover`](../gbbs_approximate_set_cover/README.md),
which is a generic approximate priority-acquisition method.

## Source and rights

Nikolaus Ruf and Anita Schöbel, “Set covering with almost consecutive ones
property,” *Discrete Optimization* 1(2), 215–228 (2004),
[DOI 10.1016/j.disopt.2004.07.002](https://doi.org/10.1016/j.disopt.2004.07.002).
The method description is also summarized in Michael Dom, “Set Cover with
Almost Consecutive Ones,” *Encyclopedia of Algorithms*, entry 368,
[DOI 10.1007/978-1-4939-2864-4_368](https://doi.org/10.1007/978-1-4939-2864-4_368).
The sources are used for algorithm ideas only; no source code or prose is
copied. See [RIGHTS.md](RIGHTS.md).

[`workload.json`](workload.json) includes branching, maximum-size, infeasible,
malformed, null, and capacity cases. The [primary oracle](primary_oracle.py)
uses interval relaxation and branch-and-bound; the
[independent oracle](independent_oracle.py) exhaustively checks column subsets.
[`verify_workload.py`](verify_workload.py) statically checks package inventory
and fixture agreement. No benchmark code has been run for this package.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/ruf_schobel_set_cover.c](../../../c/r/ruf_schobel_set_cover.c) |
| C3 | [c3/r/ruf_schobel_set_cover.c3](../../../c3/r/ruf_schobel_set_cover.c3) |
| C++ | [cpp/r/ruf_schobel_set_cover.cpp](../../../cpp/r/ruf_schobel_set_cover.cpp) |
| Elisa | [elisa/r/ruf_schobel_set_cover.elisa](../../../elisa/r/ruf_schobel_set_cover.elisa) |
| Mojo | [mojo/r/ruf_schobel_set_cover.mojo](../../../mojo/r/ruf_schobel_set_cover.mojo) |
| Nim | [nim/r/ruf_schobel_set_cover.nim](../../../nim/r/ruf_schobel_set_cover.nim) |
| Odin | [odin/r/ruf_schobel_set_cover.odin](../../../odin/r/ruf_schobel_set_cover.odin) |
| Rust | [rust/r/ruf_schobel_set_cover.rs](../../../rust/r/ruf_schobel_set_cover.rs) |
| V | [v/r/ruf_schobel_set_cover.v](../../../v/r/ruf_schobel_set_cover.v) |
| Zig | [zig/r/ruf_schobel_set_cover.zig](../../../zig/r/ruf_schobel_set_cover.zig) |
