# Strong-C1P weighted set cover by shortest path

This package implements Anita Schöbel's shortest-path method for weighted
set cover when each row is already an interval in the supplied column order.
It first removes dominated interval rows to obtain a strictly monotone matrix,
then represents each nonempty column as an interval of reduced rows. A DAG on
the column intervals encodes exactly the successive choices that cover every
row; a shortest source-to-sink path gives the minimum cover weight.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[row_count,column_count,weight_0,...,weight_(column_count-1),row_mask_0,...,row_mask_(row_count-1)]`.
There are 1–8 rows and 1–10 columns. Weights are integers in 1..20. Bit `j`
of a row mask means column `j` covers that row. Each nonzero mask must contain
one contiguous run of 1-bits in the supplied column order. A zero mask is a
valid but uncoverable row.

The exact valid input length is `2 + row_count + column_count`, at most 20
words. Parsers accept up to 21 words so a trailing-value frame is rejected.
Success emits one little-endian signed i64 with the minimum total weight. A
valid uncoverable instance emits `[-1]`. Malformed input returns `-1`; null or
undersized output returns `-2` without writes. The output is at most 8 bytes.

The row reduction is deterministic. Rows are sorted by left endpoint; equal
left endpoints retain a shortest interval, with duplicate intervals retaining
the earliest input row. A right-to-left scan then keeps strict suffix minima
of right endpoints, which applies the source's suffix-minimum reduction and
rightmost tie rule. Empty columns are omitted from the DAG. Source arcs cost
zero; every outgoing arc from selected column `j`, including its sink arc,
costs `weight[j]`. The emitted objective is therefore the total weight of the
path's columns.

This is distinct from [`almost_c1p_set_cover_enumeration`](../../a/almost_c1p_set_cover_enumeration/README.md),
which stores and enumerates feasible partial covers row by row; from
[`set_cover_domination_reduction`](../../s/set_cover_domination_reduction/README.md),
which applies presolve reductions without solving the instance; and from
[`ruf_schobel_set_cover`](../../r/ruf_schobel_set_cover/README.md), which branches
on multi-block rows and uses an interval-hitting relaxation. The shortest-path
profile handles only strong-C1P input and uses Schöbel's canonical row order
and column-interval DAG.

## Source and rights

Anita Schöbel, “Set covering problems with consecutive ones property,”
Preprint 2005-03, Institute of Numerical and Applied Mathematics, University
of Göttingen. The source gives Algorithm 1's strictly monotone row reductions
and Algorithm 2's shortest-path graph and edge costs:
[primary preprint PDF](https://num.math.uni-goettingen.de/bibi/preprintserie/preprints/schoebel/paper.pdf).
The method provides a concrete strong-C1P optimization procedure for Michael
Dom's [Encyclopedia of Algorithms entry 368](https://doi.org/10.1007/978-1-4939-2864-4_368).
Only algorithm ideas are used; no code or prose is copied. See [RIGHTS.md](RIGHTS.md).

The [workload](workload.json) includes row-reduction ties, interval gaps,
maximum-size, infeasible, malformed, null, and capacity cases. The
[primary oracle](primary_oracle.py) implements row reduction and the DAG; the
[independent oracle](independent_oracle.py) enumerates column subsets directly.
[`verify_workload.py`](verify_workload.py) checks fixtures and package
inventory statically. No program or check has been run for this package.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/strong_c1p_set_cover_shortest_path.c](../../../c/s/strong_c1p_set_cover_shortest_path.c) |
| C3 | [c3/s/strong_c1p_set_cover_shortest_path.c3](../../../c3/s/strong_c1p_set_cover_shortest_path.c3) |
| C++ | [cpp/s/strong_c1p_set_cover_shortest_path.cpp](../../../cpp/s/strong_c1p_set_cover_shortest_path.cpp) |
| Elisa | [elisa/s/strong_c1p_set_cover_shortest_path.elisa](../../../elisa/s/strong_c1p_set_cover_shortest_path.elisa) |
| Mojo | [mojo/s/strong_c1p_set_cover_shortest_path.mojo](../../../mojo/s/strong_c1p_set_cover_shortest_path.mojo) |
| Nim | [nim/s/strong_c1p_set_cover_shortest_path.nim](../../../nim/s/strong_c1p_set_cover_shortest_path.nim) |
| Odin | [odin/s/strong_c1p_set_cover_shortest_path.odin](../../../odin/s/strong_c1p_set_cover_shortest_path.odin) |
| Rust | [rust/s/strong_c1p_set_cover_shortest_path.rs](../../../rust/s/strong_c1p_set_cover_shortest_path.rs) |
| V | [v/s/strong_c1p_set_cover_shortest_path.v](../../../v/s/strong_c1p_set_cover_shortest_path.v) |
| Zig | [zig/s/strong_c1p_set_cover_shortest_path.zig](../../../zig/s/strong_c1p_set_cover_shortest_path.zig) |
