# Circle sort

Circle sort repeatedly compares mirrored pairs in each range, recursively processes its two halves, and repeats full passes until one makes no swaps. The algorithm keeps the array in place and uses logarithmic recursion depth.

## Contract

- Sort a mutable array of signed 64-bit integers in ascending order.
- Empty and one-element arrays are unchanged.
- Duplicate values and the full signed 64-bit range are supported.
- The sort is not stable.

The implementation follows the same mirrored-pair and recursive-halves strategy in the pinned Java, Python, and Go sources. The AArch64 assembly source is recorded as an architecture-specific reference only; these benchmark ports use ordinary language operations and portable compiler targets.

## Workload and verification

The workload uses deterministic modular-affine input at lengths 0, 16, 256, and 1,024. `verify_circle_sort.py` checks exhaustive short-array order and duplicate patterns, signed 64-bit edge cases, seeded random arrays, and the recorded workload through the shared sort ABI.

## Reviewed TheAlgorithms sources

- [Java CircleSort](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/CircleSort.java)
- [Python circle_sort](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/circle_sort.py)
- [Go circlesort](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/sort/circlesort.go), reviewed as a filename alias

The benchmark is a signed 64-bit in-place contract so results can be compared consistently across the nine target languages.
