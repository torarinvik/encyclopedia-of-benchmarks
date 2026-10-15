# Newton's Second Law of Motion

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/newtons_second_law_of_motion.py), which calculates net force as `mass * acceleration`.

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[mass, acceleration]`. Each input is bounded to -1,000..1,000. The source imposes no positivity checks, so negative inputs and zero are valid and the signed product is preserved. This bounded integral subset keeps the product finite. The source's exception fallback of -0.0 is outside this typed, bounded valid domain; invalid ABI lengths or values return -1e300.

The output is binary64 force in newtons. Runtime and auxiliary space are O(1).
