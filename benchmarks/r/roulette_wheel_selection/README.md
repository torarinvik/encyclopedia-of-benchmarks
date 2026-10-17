# Roulette wheel selection

Select one validator in proportion to its positive stake. This package represents the random draw as an explicit integer ticket, making each call deterministic while preserving the source algorithms' weighted selection probabilities.

## Contract

Input is a signed 64-bit integer array in the form [n, stake_1, ..., stake_n, ticket]. The exact length is n + 2. Validator count is 1 through 128. Each stake is 1 through 1,000,000, so the total stake is 1 through 128,000,000. The ticket is an integer from zero through total_stake - 1. The maximum valid input length is 130 values; the parser accepts up to 131 values so a trailing value can be rejected at the cap.

The ticket t represents the midpoint draw t + 1/2. Scan stakes in original order and return the one-based index of the first validator whose cumulative stake is strictly greater than t. A uniform ticket selects validator i with probability exactly stake_i / total_stake. The midpoint lies away from cumulative boundaries, which makes the comparison agree with both Python's cumulative weighted choice and MATLAB's inclusive comparison.

The interface abstracts the different PRNG streams used by the sources; it does not reproduce a particular Python or MATLAB random sequence. A caller can generate tickets with any unbiased uniform integer draw over 0..total_stake-1. The same input always returns the same validator index. Invalid input returns -1.

The Python source returns one of the original Validator objects; this adapter reports its one-based position in the input list. The MATLAB source already reports a one-based index.

## Pinned sources

- Python choose_validator in [proof_of_stake.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/blockchain/proof_of_stake.py), commit e1a2a8b016001309a73d5fec4818c35cca139795.
- MATLAB RouletteWheelSelection in [RouletteWheelSelection.m](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/RouletteWheelSelection.m), commit e150b77ad256de46c1ce3815c3d7945ac4fc28dc.

The catalog maps proof_of_stake to this shared weighted-selection benchmark; the source only implements validator selection, not a full consensus protocol.

See the workload and oracle.

| Language | Port |
|---|---|
| C | [c/r/roulette_wheel_selection.c](../../../c/r/roulette_wheel_selection.c) |
| C3 | [c3/r/roulette_wheel_selection.c3](../../../c3/r/roulette_wheel_selection.c3) |
| C++ | [cpp/r/roulette_wheel_selection.cpp](../../../cpp/r/roulette_wheel_selection.cpp) |
| Elisa | [elisa/r/roulette_wheel_selection.elisa](../../../elisa/r/roulette_wheel_selection.elisa) |
| Nim | [nim/r/roulette_wheel_selection.nim](../../../nim/r/roulette_wheel_selection.nim) |
| Odin | [odin/r/roulette_wheel_selection.odin](../../../odin/r/roulette_wheel_selection.odin) |
| Rust | [rust/r/roulette_wheel_selection.rs](../../../rust/r/roulette_wheel_selection.rs) |
| V | [v/r/roulette_wheel_selection.v](../../../v/r/roulette_wheel_selection.v) |
| Zig | [zig/r/roulette_wheel_selection.zig](../../../zig/r/roulette_wheel_selection.zig) |
