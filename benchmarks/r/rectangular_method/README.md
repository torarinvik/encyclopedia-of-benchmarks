# Rectangular method

This benchmark ports the left and right rectangle rules from the pinned Jupyter rectangles(a, b, n) function. It evaluates the fixed integrand f(x) = (e^x / 2) * (cos(x) - sin(x)). The notebook's separate integration() helper is out of scope.

## Contract

The i64_array_float64 input is [a_quarters, b_quarters, n, rule], with exactly four values. Endpoints are the first two values divided by 4. They must satisfy -64 <= a_quarters < b_quarters <= 64; n must be 1 through 64 and divide b_quarters - a_quarters; rule is 0 for the left rule or 1 for the right rule. These bounds make the step an exactly representable multiple of one quarter, so the source's repeated additions reach b after exactly n iterations.

For the left rule, each panel adds f(x) * h before advancing x by h. For the right rule, it advances x first and then adds f(x) * h. The scalar result is the selected sum. Invalid inputs return -1e300. The output tolerance is 1e-12 absolute and relative.

The input parser admits five values to reject a trailing extra element; valid input length is exactly four. The bounded endpoint and step domain keeps all samples finite.

## Pinned source and fixtures

The source is [TheAlgorithms/Jupyter the_rectangular_method.ipynb](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/numerical_methods/the_rectangular_method.ipynb) at commit ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9. The source notebook's example on [2, 3] with four panels produces the left result -7.576924395545134 and right result -9.192576890365931.

The workload covers both rules, the source example, the simplest left-rule case, invalid interval lengths, non-dividing panel counts, invalid selectors, and endpoint bounds. The independent oracle is in benchmarks/rectangular_method_oracle.py.

## Implementations

| Language | Source |
| --- | --- |
| C | c/r/rectangular_method.c |
| C3 | c3/r/rectangular_method.c3 |
| C++ | cpp/r/rectangular_method.cpp |
| Elisa | elisa/r/rectangular_method.elisa |
| Nim | nim/r/rectangular_method.nim |
| Odin | odin/r/rectangular_method.odin |
| Rust | rust/r/rectangular_method.rs |
| V | v/r/rectangular_method.v |
| Zig | zig/r/rectangular_method.zig |
