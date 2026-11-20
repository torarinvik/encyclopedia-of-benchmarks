# Metropolis–Hastings with asymmetric proposals

This profile replays a bounded finite-state Markov chain using an explicitly
asymmetric proposal kernel. For a current state `x` and supplied proposal `y`,
the acceptance probability is

`min(1, weight[y] * Q[y,x] / (weight[x] * Q[x,y]))`.

The target weights may be unnormalized. Proposal rows contain nonnegative
integer weights summing to 1024, so `Q[i,j] / 1024` is the proposal
probability. The common denominator cancels in the Hastings correction. Every
draw is supplied as an exact rational pair `u_num/u_den`, with
`0 <= u_num < u_den <= 1024`; the transition compares the two ratios by exact
integer cross multiplication. This avoids floating-point drift and does not
round an acceptance threshold to a finite grid. The supplied proposal tape is
checked against the current row of `Q` as the chain is replayed.

## Contract

- Exported symbol: `metropolis_hastings_asymmetric_proposal`; ABI:
  `i64_array_bytes_output`.
- Input: `[N, T, initial, weights[N], Q[N*N], proposals[T],
  (u_num, u_den)[T]]`, where `2<=N<=8`, `0<=T<=64`, and states are numbered
  `0..N-1`.
- Each target weight is in `1..1024`. Each proposal row contains values in
  `0..1024` and sums to 1024. Each supplied proposal must have positive weight
  in the current state's row. Rational draw pairs satisfy
  `0<=u_num<u_den<=1024`.
- The exact input length is `3 + N + N*N + 3*T`; the maximum valid frame is 267 i64 words. The byte-suite parseable bound is 268 words so a trailing-word frame can be rejected explicitly.
- Output is the state trace as one byte per state: initial state, then the
  resulting state after each proposal. The successful return value is `T+1`;
  maximum output and staged workspace are 65 bytes. Invalid input returns
  `-1`; a null or short output buffer returns `-2` without writing.
- If `x==y`, the move is accepted. If `Q[y,x]==0`, the acceptance probability
  is zero. Otherwise the implementation accepts exactly when
  `u_num * (weight[x]*Q[x,y]) < u_den * (weight[y]*Q[y,x])` when the ratio is
  below one. All products fit signed 64-bit integers under the stated bounds.
- The trace is a deterministic replay. The supplied rational variates are not
  claimed to be independent random samples; the profile makes no burn-in,
  mixing-time, or convergence claim.

The repository's [`metropolis_mcmc`](../metropolis_mcmc/README.md) implements
the symmetric-proposal Metropolis rule using an energy/temperature ratio. This
profile includes the reverse/forward proposal correction, making asymmetric
proposal matrices part of the measured transition.

## References and files

The [Algorithm Archive Metropolis chapter](https://www.algorithm-archive.org/contents/metropolis/metropolis.html)
names Metropolis–Hastings as a generalization. The acceptance correction
follows W. K. Hastings, [“Monte Carlo sampling methods using Markov chains and
their applications”](https://doi.org/10.1093/biomet/57.1.97), *Biometrika*
57(1), 97–109 (1970). The bounded integer matrix and rational draw tape are
independently specified here; no source code, chapter prose, examples, or
fixtures are reused.

- [`primary_oracle.py`](primary_oracle.py) replays the exact cross-product
  transition.
- [`independent_oracle.py`](independent_oracle.py) builds exact rational
  acceptance cutoffs and checks detailed balance for the supplied proposal
  kernel.
- [`workload.json`](workload.json) records bounded valid and error cases.
- [`INVENTORY.md`](INVENTORY.md), [`inventory.json`](inventory.json), and
  [`check_inventory.py`](check_inventory.py) pin the ten source paths and
  fixture/result contract.
- [`RIGHTS.md`](RIGHTS.md) records provenance and clean-room scope.

The ten source paths are listed in the inventory. They have not been compiled
or executed.
