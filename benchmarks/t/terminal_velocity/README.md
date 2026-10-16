# Terminal Velocity

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/terminal_velocity.py). It returns `((2 * mass * g) / (density * area * drag_coefficient)) ** 0.5`, where the source imports standard gravity `g = 9.80665` m/s².

The `i64_array_float64` ABI accepts exactly four signed integers in this order: `[mass, density, area, drag_coefficient]`. Each value is bounded to 1..1,000. This positive integer subset satisfies all four source positivity guards and keeps numerator and denominator finite. Ports retain the source multiplication grouping, divide the numerator by the denominator, then take the square root. Invalid lengths and values return -1e300.

The output is binary64 terminal velocity in metres per second, compared with absolute and relative tolerances of `1e-12` to allow for small differences among language math libraries. Runtime and auxiliary space are O(1).
