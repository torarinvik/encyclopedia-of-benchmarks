package fractional_differentiation
import "core:c"
import "core:runtime"

@(export)
fractional_differentiation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    context = runtime.default_context()
    if values == nil || length < 4 || length > 18 do return -1.0e300
    n := int(length) - 2; d_units, window := values[0], values[1]
    if d_units < 0 || d_units > 1000000 || window < 1 || window > 8 || n <= int(window) || n > 16 do return -1.0e300
    for i := 0; i < n; i += 1 { if values[i+2] < -1000000 || values[i+2] > 1000000 do return -1.0e300 }
    d := f64(d_units) / 1000000.0
    weights: [8]f64; weights[0] = 1
    for k := 1; k < int(window); k += 1 { weights[k] = -weights[k-1] * (d - f64(k) + 1) / f64(k) }
    result := 0.0
    for j := 0; j < int(window); j += 1 { result += weights[j] * (f64(values[2+n-1-j]) / 1000.0) }
    return result
}
