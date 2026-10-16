# Viterbi decoding

This benchmark is based on the pinned Nim and Python sources listed in
`catalog/algorithm-candidates.json`. Both implement Viterbi decoding for a
hidden Markov model: dynamic programming over state probabilities followed by
backpointer reconstruction. It is distinct from shortest-path graph benchmarks
because it decodes a sequence using an HMM's start, transition, and emission
probabilities.

The portable contract specializes the pinned Python Wikipedia example to its
two states (`Healthy`, `Fever`) and three observations (`Normal`, `Cold`,
`Dizzy`). Inputs are observation IDs `0`, `1`, and `2`, with sequence lengths
from 1 through 64. The model parameters are fixed to the example's published
start, transition, and emission probabilities. Output is the most likely
state ID at each observation, with the first declared state winning ties.
Malformed inputs return `-1`; insufficient output capacity returns `-2`.

The independent oracle and byte-output ABI use little-endian signed 64-bit
state IDs. The workload includes the pinned three-observation example, short
exhaustive sequences, and length-boundary inputs.

Run the focused verifier across all language ports with:

```sh
python3 benchmarks/verify_viterbi.py --elisa-compiler ../Elisa-compiler/build/elisac-go-stage0-current
```

All nine benchmark ports are in `c/v`, `c3/v`, `cpp/v`, `elisa/v`, `nim/v`,
`odin/v`, `rust/v`, `v/v`, and `zig/v`.
