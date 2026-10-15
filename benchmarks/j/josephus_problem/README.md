# Josephus problem by iterative recurrence

Return the one-based surviving participant using the linear recurrence. Starting with zero-based survivor J(1)=0, update `J(size) = (J(size - 1) + step) mod size` for each circle size.

## Contract

- Input is `[participant_count, elimination_step]` as two signed 64-bit values.
- Participant count is 1 through 100,000; step is positive.
- Counting starts with participant 1, and each step counts the current participant as the first person.
- Return the one-based survivor. Invalid input returns -1.

Reduce the step modulo the current circle size before adding, so large steps do not overflow. This strategy takes O(n) time and constant extra space. Direct recursion and list simulation are benchmarked separately with the same survivor semantics and smaller bounds.

## Workload and verification

The workload covers published examples, steps larger than the circle, a 100,000-person input, signed boundaries, malformed arrays, and invalid values. [`verify_josephus_problem.py`](../../verify_josephus_problem.py) checks all three strategies against a recurrence oracle in all nine languages.

## Reviewed TheAlgorithms sources

Java defines the recursive recurrence and returns a one-based winner. R uses the iterative recurrence. Python provides both the recurrence and direct list simulation. The cataloged C# source path does not resolve at its pinned revision; AArch64 assembly is only a discovery reference.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
