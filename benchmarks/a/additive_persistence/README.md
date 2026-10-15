# Additive persistence

This benchmark returns the number of repeated decimal digit-sum steps needed to reduce a nonnegative integer to one digit.

## Contract

- Input is a signed 64-bit integer from 0 through 9,223,372,036,854,775,807.
- While the current value has at least two decimal digits, sum its digits, replace the value with that sum, and count one step.
- Zero and all one-digit values return 0.
- Negative inputs return -1 as the benchmark's invalid-input sentinel.

The contract follows `additive_persistence` in the pinned Python `maths/persistence.py` source. The benchmark uses the full nonnegative signed-64-bit ABI domain; digit sums remain small and fit in signed 64-bit. It is distinct from `digital_root`: both produce the same terminal digit mathematically, but this benchmark returns the number of digit-sum steps instead.

## Upstream sources

- [TheAlgorithms/Python `additive_persistence`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/persistence.py)
- [TheAlgorithms/Java `NumberPersistence.additivePersistence`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/NumberPersistence.java)

## Workload

[`workload.json`](workload.json) covers zero and one-digit values, one and multiple reductions, repeated nines, the signed-64-bit upper bound, and invalid negative input.
