# Josephus problem by list simulation

Simulate eliminations directly: count from the current position, remove every step-th participant, and continue until one remains.

## Contract

- Input is `[participant_count, elimination_step]` as two signed 64-bit values.
- Participant count is 1 through 512; step is positive.
- Return the one-based survivor. Invalid input returns -1.

A fixed-capacity array shifts the remaining participants after each removal, matching the list-removal strategy in the pinned Python source. This has quadratic worst-case work and remains separate from the linear recurrence.

## Workload and verification

[`verify_josephus_problem.py`](../../verify_josephus_problem.py) checks exhaustive small participant/step pairs, large steps, boundary cases, and the workload in all nine languages.

## Reviewed TheAlgorithms source

Python's `josephus_iterative` function represents the circle as a list and removes eliminated entries by index. The benchmark standardizes the one-based survivor result.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
