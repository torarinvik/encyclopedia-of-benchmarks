# Baum–Welch re-estimation

Perform one Baum–Welch expectation-maximization update for a dense discrete
hidden Markov model and one observed symbol sequence. The forward and backward
passes compute posterior state and transition probabilities; their expected
counts re-estimate the initial-state, transition, and emission distributions.

## Contract

- ABI: `int64_t baum_welch_reestimation(const double *input, size_t input_length, double *output, size_t output_capacity)` (`float64_slice_io`).
- Input is `[state_count, symbol_count, sequence_length, initial[S], transition[S*S], emission[S*M], observations[T]]`. Dimensions and observation indices must be exact integers represented as finite float64 values. Transition and emission matrices are row-major.
- State count `S` and symbol count `M` are 2..4; sequence length `T` is 1..8. Every model probability is in `[0.001, 1]`; the initial distribution and each transition/emission row must sum to 1 within `1e-9`. Observation symbols are in `0..M-1`.
- Return the re-estimated initial distribution, transition matrix, and emission matrix in that order, for `S + S*S + S*M` float64 values. Return the element count. Output comparisons use absolute and relative tolerance `1e-9`.
- `T=1` has no observed transitions, so the transition matrix is copied from the input; initial and emission distributions are still re-estimated.
- Invalid input, including an unsupported dimension, malformed frame, non-finite/fractional metadata, invalid observation, or non-normalized model row, returns `-1`. Null output or insufficient element capacity returns `-2` after input validation and calculation. Errors leave output untouched.

## Relationship to existing profiles

[`viterbi`](../../v/viterbi/README.md) decodes one most-likely hidden-state path
for a supplied HMM. Baum–Welch instead uses forward–backward posterior
expectations to update the HMM parameters; it does not select a single path.
The local Viterbi profile therefore shares the model representation but not
the operation being benchmarked.

## Workload and references

[`workload.json`](workload.json) covers a nontrivial two-state re-estimation,
the single-observation transition rule, a longer symmetric sequence, malformed
dimensions and frames, invalid probability rows and observations, and output
errors. The primary reference uses forward and backward dynamic-programming
tables. The independent reference enumerates every hidden-state path and
accumulates its likelihood-weighted sufficient statistics; the bound
`S^T <= 4^8` keeps that reference finite.

The candidate was discovered in NIST's [Dictionary of Algorithms and Data
Structures](https://xlinux.nist.gov/dads/HTML/baumWelch.html) and its [unified
title index](https://xlinux.nist.gov/dads/ui.html). Lawrence R. Rabiner's
[HMM tutorial](https://doi.org/10.1109/5.18626) gives the forward–backward
recurrences and Baum–Welch re-estimation equations. NIST's [Viterbi
entry](https://xlinux.nist.gov/dads/HTML/viterbi.html) describes decoding as a
separate HMM task. These sources are used for algorithm descriptions only; no
source code, examples, or test data were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/b/baum_welch_reestimation.c`](../../../c/b/baum_welch_reestimation.c) |
| C3 | [`c3/b/baum_welch_reestimation.c3`](../../../c3/b/baum_welch_reestimation.c3) |
| C++ | [`cpp/b/baum_welch_reestimation.cpp`](../../../cpp/b/baum_welch_reestimation.cpp) |
| Elisa | [`elisa/b/baum_welch_reestimation.elisa`](../../../elisa/b/baum_welch_reestimation.elisa) |
| Mojo | [`mojo/b/baum_welch_reestimation.mojo`](../../../mojo/b/baum_welch_reestimation.mojo) |
| Nim | [`nim/b/baum_welch_reestimation.nim`](../../../nim/b/baum_welch_reestimation.nim) |
| Odin | [`odin/b/baum_welch_reestimation.odin`](../../../odin/b/baum_welch_reestimation.odin) |
| Rust | [`rust/b/baum_welch_reestimation.rs`](../../../rust/b/baum_welch_reestimation.rs) |
| V | [`v/b/baum_welch_reestimation.v`](../../../v/b/baum_welch_reestimation.v) |
| Zig | [`zig/b/baum_welch_reestimation.zig`](../../../zig/b/baum_welch_reestimation.zig) |
