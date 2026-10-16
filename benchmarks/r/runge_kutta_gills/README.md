# Runge–Kutta–Gill

This package ports the pinned [Runge–Kutta–Gill routine](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/runge_kutta_gills.py). It preserves the source's four Gill stages, `sqrt(2)` coefficients, and update order. The source takes `int((x_final - x_initial) / step_size)` full steps and returns the final value in its `y` array.

The `i64_array_float64` input is `[function_id, y0_micro, x0_micro, h_micro, x_end_micro]`. Function IDs 0–4 select `y`, `x`, `x+y`, `(x-y)/2`, and `1+y*y`. Divide state and coordinate fields by 1,000,000. Require `y0`, `x0`, and `x_end` in [-1,1], `h` in [0.01,0.25], `x_end > x0`, at least one full step, and at most 64 steps. For function 4, also require `x0 >= 0` and `y0 <= 0` so every stage remains before its tangent pole. Invalid or nonfinite results return `-1e300`.

The maximum input is 5 signed-i64 values (40 packed bytes). Output tolerance is absolute `1e-9` and relative `1e-12`. The independent oracle is [`runge_kutta_gills_oracle.py`](../../runge_kutta_gills_oracle.py), with shared arithmetic in [`runge_kutta_common_oracle.py`](../../runge_kutta_common_oracle.py).
