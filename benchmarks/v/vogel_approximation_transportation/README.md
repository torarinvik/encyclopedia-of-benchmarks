# Vogel approximation method for transportation tables

This scalar profile builds a deterministic feasible allocation using Vogel's
approximation method (VAM). It differs from exact `minimum_cost_b_flow`: VAM
uses row/column penalties to construct an initial solution and does not promise
that this allocation has minimum cost.

## Contract

The ABI is `int64_t vogel_approximation_transportation(const int64_t *input,
size_t length)`. Input is `[R,C,costs row-major,supply[R],demand[C]]` with
`1<=R,C<=3`, costs in `0..9`, and every supply and demand in `1..3`. Total
supply must equal total demand. The exact length is `2+R*C+R+C`, at most 17
valid words; an 18-word frame is parseable and rejected as trailing input.
Null, malformed, unbalanced, or out-of-range input returns `-1`.

At each step compute each active row and column penalty as its second-smallest
remaining cell cost minus its smallest. A line with one active cell uses
penalty 10, larger than any finite penalty in this cost domain. Choose the
largest penalty; scan rows in increasing order before columns in increasing
order and keep the first line on ties. In that line choose the lowest-cost
active cell, breaking equal cell costs by the lowest partner index. Allocate
as much as possible, subtract the amount from its supply and demand, and
remove all exhausted rows and columns. Repeat until every margin is zero.

The returned scalar is `total_cost*4^9 + allocation_signature`. The low nine
base-four digits encode a fixed 3x3 row-major allocation matrix; missing cells
are zero. Since margins are at most three, every allocation fits one digit.
The maximum valid scalar is `81*4^9+(4^9-1) = 21,495,807`. The primary scans
candidate penalties directly in `O((R+C)*R*C)` time; the independent reference
reconstructs and sorts each active line's cost list in
`O((R+C)*R*C*log(max(R,C)))`. Both use `O(R*C+R+C)` storage.

Fixtures cover row-before-column ties, a strict penalty winner, singleton
remaining cells, invalid balance/margins/costs, the maximum frame and
parseable length. `verify_workload.py` checks both Python references, and
`check_inventory.py` exposes `static_issues()` for static package inventory.

## Provenance and rights

Shore, [“The Transportation Problem and the Vogel Approximation
Method”](https://doi.org/10.1111/j.1540-5915.1970.tb00792.x), discusses VAM as a
shortcut for finding an initial feasible transportation solution and notes
that it need not be optimal. The penalty and allocation steps are cross-checked
against the Open University [Optimization Techniques-I chapter](https://egyankosh.ac.in/bitstream/123456789/28668/1/Unit-7.pdf).
The RosettaGit [task title](https://rosettagit.org/tasks/vogels-approximation-method/)
was used only for discovery. No task prose, examples, tests, or source code
were copied; the deterministic tie profile, all code, and fixtures were
authored for this repository. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [vogel_approximation_transportation.c](../../../c/v/vogel_approximation_transportation.c) |
| C3 | [vogel_approximation_transportation.c3](../../../c3/v/vogel_approximation_transportation.c3) |
| C++ | [vogel_approximation_transportation.cpp](../../../cpp/v/vogel_approximation_transportation.cpp) |
| Elisa | [vogel_approximation_transportation.elisa](../../../elisa/v/vogel_approximation_transportation.elisa) |
| Mojo | [vogel_approximation_transportation.mojo](../../../mojo/v/vogel_approximation_transportation.mojo) |
| Nim | [vogel_approximation_transportation.nim](../../../nim/v/vogel_approximation_transportation.nim) |
| Odin | [vogel_approximation_transportation.odin](../../../odin/v/vogel_approximation_transportation.odin) |
| Rust | [vogel_approximation_transportation.rs](../../../rust/v/vogel_approximation_transportation.rs) |
| V | [vogel_approximation_transportation.v](../../../v/v/vogel_approximation_transportation.v) |
| Zig | [vogel_approximation_transportation.zig](../../../zig/v/vogel_approximation_transportation.zig) |
