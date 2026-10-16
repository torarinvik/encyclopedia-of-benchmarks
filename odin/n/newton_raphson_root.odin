package newton_raphson_root

import "core:math"

@(export)
newton_raphson_root :: proc "c" (x0: f64) -> f64 {
    if math.is_nan(x0) || math.is_inf(x0) || x0 < 1.0 || x0 > 4.0 do return -1e300
    x := f32(x0)
    for i := 0; i < 1000; i += 1 {
        square := x * x
        residual := square - f32(3.0)
        if math.abs(residual) <= f32(1e-6) do return f64(x)
        derivative := f32(2.0) * x
        if derivative == 0 do return -1e300
        x = x - residual / derivative
    }
    return f64(x)
}
