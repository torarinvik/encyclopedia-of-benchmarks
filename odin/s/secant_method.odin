package secant_method

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

python_objective :: proc "contextless"(x: f64) -> f64 {
    return 8.0 * x - 2.0 * math.exp_f64(-x)
}

c_variant :: proc "contextless"() -> f64 {
    x0, x1 := f64(0.2), f64(0.5)
    tolerance := 100.0 / 1000000.0
    for iteration in 0..<99 {
        f1 := x1 * x1 - 3.0
        f0 := x0 * x0 - 3.0
        x2 := x1 - f1 * (x1 - x0) / (f1 - f0)
        x0, x1 = x1, x2
        if math.abs(x1 - x0) < tolerance do return x2
    }
    return -1.0
}

python_variant :: proc "contextless"(repeats: i64) -> f64 {
    x0, x1 := f64(1.0), f64(3.0)
    for iteration: i64 = 0; iteration < repeats; iteration += 1 {
        f1 := python_objective(x1)
        f0 := python_objective(x0)
        x2 := x1 - (f1 * (x1 - x0)) / (f1 - f0)
        x0, x1 = x1, x2
    }
    return x1
}

@(export)
secant_method :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length != 2 do return INVALID_RESULT
    variant, control := values[0], values[1]
    if variant == 0 && control == 100 do return c_variant()
    if variant == 1 && control >= 0 && control <= 2 do return python_variant(control)
    return INVALID_RESULT
}
