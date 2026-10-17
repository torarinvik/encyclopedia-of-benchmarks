package secant

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

objective :: proc "contextless"(x: f64) -> f64 { return x * x - 3.0 }

@(export)
secant :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 5 do return INVALID_RESULT
    if values[0] != 0 || values[1] < 1_000_000 || values[1] > 1_500_000 ||
        values[2] < 1_600_000 || values[2] > 2_000_000 || values[1] >= values[2] ||
        values[3] < 1 || values[3] > 100_000 || values[4] < 0 || values[4] > 32 do return INVALID_RESULT
    x0 := f64(values[1]) / 1_000_000.0
    x1 := f64(values[2]) / 1_000_000.0
    tolerance := f64(values[3]) / 1_000_000_000.0
    max_updates := values[4]
    for update: i64 = 0; update <= max_updates; update += 1 {
        f1 := objective(x1)
        if math.abs(f1) <= tolerance do return x1
        if update == max_updates do break
        f0 := objective(x0)
        denominator := f1 - f0
        if denominator == 0.0 do return INVALID_RESULT
        x2 := x1 - f1 * (x1 - x0) / denominator
        x0, x1 = x1, x2
    }
    return INVALID_RESULT
}
