# Resistor Equivalence

This package benchmarks the two functions in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/resistor_equivalence.py): parallel equivalent resistance and series equivalent resistance.

The `i64_array_float64` ABI accepts `[operation, resistor_1, ..., resistor_n]`, with 1..32 resistor values following the operation. Operation 0 computes parallel resistance by accumulating `1.0 / resistor` sequentially, then returning the reciprocal of that sum. Every parallel resistor must be positive, matching the source's guard. Operation 1 sums resistor values sequentially and rejects negative values; zero is valid, as in the source. Values are bounded to 0..1,000 ohms. The integer-ohm encoding is the benchmark's normalized discrete input subset; the output is in ohms. Empty lists are outside the supported ABI domain. Invalid length, operation, or mode-specific resistor values return -1e300.

The output is binary64 with relative and absolute tolerances of 1e-12. Runtime is O(n) and auxiliary space is O(1).
