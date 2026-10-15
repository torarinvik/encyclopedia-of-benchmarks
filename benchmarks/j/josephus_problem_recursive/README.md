# Josephus problem by direct recursion

Return the one-based survivor using the direct recursive recurrence `J(1)=0`, `J(n)=(J(n-1)+step) mod n`, then add one for participant numbering.

## Contract

- Input is `[participant_count, elimination_step]` as two signed 64-bit values.
- Participant count is 1 through 256; step is positive.
- Return the one-based survivor. Invalid input returns -1.

The bound limits recursion depth. The linear recurrence uses the same recurrence with constant call-stack space and a larger input bound; list simulation is also benchmarked separately.

## Workload and verification

[`verify_josephus_problem.py`](../../verify_josephus_problem.py) checks exhaustive small participant/step pairs, large steps, and boundary cases in all nine languages.

## Reviewed TheAlgorithms sources

Java and Python contain direct recursive implementations. Java's `winner` helper returns a zero-based position, and Python adds one in `find_winner`.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
