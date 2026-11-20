# Jacobson–Matthews Latin-square chain

This package implements the proper/improper 3-cycle transition of the
Jacobson–Matthews Markov chain for Latin squares. The procedure uses a
three-dimensional 0/1 tensor whose axis-parallel line sums are one. A proper
state is a Latin square. An improper state contains one -1 and otherwise only
zeros and ones.

## Bounded profile

The exported `jacobson_matthews_latin_square_chain` function uses the
`i64_array_bytes_output` ABI. Input is `[n, step_count, choice_0, ...]`, where
`2 <= n <= 4`, `0 <= step_count <= 12`, and the length is exactly
`2 + step_count`. The initial tensor is cyclic:
`A[i,j,k] = 1` exactly when `k = (i+j) mod n`.

Each tape value chooses a move by zero-based rank in lexicographic order. In a
proper state the candidates are all zero cells `(i,j,k)`, ordered by `i,j,k`;
their three line mates are the unique `i'`, `j'`, and `k'` for which
`A[i',j,k]`, `A[i,j',k]`, and `A[i,j,k']` equal one. In an improper state the
pivot is the unique -1 cell `(i,j,k)`. Candidates are all lexicographically
ordered triples `(i',j',k')` for which `A[i,j,k']`, `A[i,j',k]`, and
`A[i',j,k]` equal one. There are eight candidates.

For either case, the selected move adds one at `(i,j,k)`, `(i',j',k)`,
`(i',j,k')`, and `(i,j',k')`, and subtracts one at `(i',j,k)`, `(i,j',k)`,
`(i,j,k')`, and `(i',j',k')`. A choice outside the current candidate range is
invalid. The tape makes every random choice explicit, so this is a deterministic
trajectory profile rather than a sampler. It makes no mixing-time or
uniform-sampling claim.

Success writes `[n, steps_applied, A[0,0,0], ..., A[n-1,n-1,n-1]]`, with the
tensor flattened in `i,j,k` order as little-endian signed 64-bit words. The
maximum output is 528 bytes; fixed workspace is at most 4,096 bytes. Invalid
input or a tape rank outside the legal move set returns `-1` without writing.
Null output or insufficient capacity returns `-2`, also without writing.

The chain's objective and state space differ from local magic-square
benchmarks. Those construct integer grids satisfying row, column, and often
diagonal sum constraints. This chain moves among one-hot 3D contingency tables
whose line sums are one; it neither constructs nor searches for a magic square.

The method follows Mark T. Jacobson and Peter Matthews, “Generating uniformly
distributed random latin squares,” *Journal of Combinatorial Designs* 4(6),
405–437 (1996), DOI
[10.1002/(SICI)1520-6610(1996)4:6<405::AID-JCD3>3.0.CO;2-J](https://doi.org/10.1002/%28SICI%291520-6610%281996%294%3A6%3C405%3A%3AAID-JCD3%3E3.0.CO%3B2-J),
and the transition description in ETH Zürich's *Random Algorithms II*,
Section 2.9.2, [“Matthew and Jacobson’s Markov chain”](https://cadmo.ethz.ch/education/lectures/FS15/rand_alg_2/ETHSkript.pdf).
RosettaGit's title index was used only to discover the algorithm name; no
Rosetta implementation or text is included. See [RIGHTS.md](RIGHTS.md).

[`primary_oracle.py`](primary_oracle.py) follows the line-mate and eight-corner
description directly. [`independent_oracle.py`](independent_oracle.py) finds
moves by exhaustive tensor-coordinate filtering, applies corners by parity,
and independently checks the line-sum and cell-value invariants.
[`workload.json`](workload.json) gives deterministic trajectories including a
proper-to-improper step followed by a move from the improper state.

