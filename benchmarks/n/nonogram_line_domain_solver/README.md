# Nonogram line-domain solver

This package solves small monochrome nonograms from row and column run clues.
It is a clean-room bounded profile discovered from the RosettaGit mirror's
[Rosetta Code “Nonogram solver” title](https://rosettagit.org/tasks/nonogram-solver/);
no Rosetta task prose, examples, tests, or implementations are used.

## Contract

The exported symbol is `nonogram_line_domain_solver` in the
`i64_array_bytes_output` family. Input is `[height,width, row clue blocks,
column clue blocks]`. Each line block is exactly five signed 64-bit words:
`[run_count, run_0, run_1, run_2, run_3]`. Unused run slots must be zero.
Dimensions are each in `1..8`; a line has at most four positive run lengths,
whose required cells and separators fit its length. The exact input length is
`2 + 5*height + 5*width` (at most 82 words). Row and column totals must agree.

Output is `height*width` bytes in row-major order, each exactly 0 or 1. The
solver returns the lexicographically first row-mask tuple, with candidate
masks tried in increasing unsigned integer order and bit `c` representing
column `c`. Invalid or unsatisfiable inputs return `-1`; a null or short
output buffer for a valid solvable input returns `-2`. Errors write no bytes.
The output is at most 64 bytes. The caller output buffer is capped at 64 bytes;
solver state and recursive domain snapshots have a separate conservative bound
of 65,536 bytes.

## Algorithm and bounds

For each row and column, the primary initializes a domain with every bit mask
whose maximal one-runs equal that line's clue. It repeatedly enforces binary
cell-equality support between each row domain and its crossing column domain,
removing patterns with no crossing-line support. If a domain empties, the
branch is inconsistent. Once support filtering reaches a fixed point, depth
first search fixes the first unresolved row, trying its remaining masks in
ascending order. This yields the first valid row-mask tuple under the stated
ordering. The profile does not implement the optimized line dynamic program,
fully-probing heuristics, or tournament solver described in the cited paper.

There are at most 16 lines and 256 masks per line. Domain storage is at most
16*256 Boolean candidates (represented as four 64-bit words per line in the
ports). Each successful propagation sweep removes at least one candidate;
the finite-domain bound is 4,096 removals. A sweep visits at most 64 cell
crossings and scans at most 256 masks per participating line. Search depth is
at most eight row choices; total search remains exponential in the bounded
profile, with at most 256 choices per level. The bound favors a reproducible
cross-language exact workload over claims of large-puzzle performance.

The primary Python reference mirrors line-domain support propagation and
ordered row branching. The independent reference recursively enumerates full
row-mask tuples in the same defined order and validates completed column runs
directly, without domain propagation.

## Workload and files

[`workload.json`](workload.json) covers empty and filled cells, a forced cross,
an ambiguous 2x2 puzzle with deterministic tie behavior, unsatisfiable clues,
malformed framing, and output-capacity failure. The two references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The `i64_array_bytes_output`
runner and verifier dispatch, oracle paths, output capacity, and static source
inventory review are registered; none has been executed.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/nonogram_line_domain_solver.c`](../../../c/n/nonogram_line_domain_solver.c) |
| C3 | [`c3/n/nonogram_line_domain_solver.c3`](../../../c3/n/nonogram_line_domain_solver.c3) |
| C++ | [`cpp/n/nonogram_line_domain_solver.cpp`](../../../cpp/n/nonogram_line_domain_solver.cpp) |
| Elisa | [`elisa/n/nonogram_line_domain_solver.elisa`](../../../elisa/n/nonogram_line_domain_solver.elisa) |
| Mojo | [`mojo/n/nonogram_line_domain_solver.mojo`](../../../mojo/n/nonogram_line_domain_solver.mojo) |
| Nim | [`nim/n/nonogram_line_domain_solver.nim`](../../../nim/n/nonogram_line_domain_solver.nim) |
| Odin | [`odin/n/nonogram_line_domain_solver.odin`](../../../odin/n/nonogram_line_domain_solver.odin) |
| Rust | [`rust/n/nonogram_line_domain_solver.rs`](../../../rust/n/nonogram_line_domain_solver.rs) |
| V | [`v/n/nonogram_line_domain_solver.v`](../../../v/n/nonogram_line_domain_solver.v) |
| Zig | [`zig/n/nonogram_line_domain_solver.zig`](../../../zig/n/nonogram_line_domain_solver.zig) |

## Sources

I.-C. Wu et al., “An Efficient Approach to Solving Nonograms,” *IEEE
Transactions on Computational Intelligence and AI in Games* 5(3), 2013,
[DOI 10.1109/TCIAIG.2013.2251884](https://doi.org/10.1109/TCIAIG.2013.2251884),
[author-hosted paper](https://ir.lib.nycu.edu.tw/bitstream/11536/22772/1/000324586300005.pdf).
The paper motivates line solving followed by search; this package specifies a
separate finite-domain support-propagation profile and does not claim to
reproduce its optimized subroutines.

See [RIGHTS.md](RIGHTS.md) for provenance and reuse boundaries.
