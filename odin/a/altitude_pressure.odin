package altitude_pressure

import "core:math"

// Estimate altitude from pressure using the pinned source formula.
@(export)
altitude_pressure :: proc "c" (pressure: f64) -> f64 {
    if pressure < 0.0 || pressure > 101325.0 do return -1.0
    if pressure == 0.0 do return 44330.0
    exponent := 1.0 / 5.5255
    return 44330.0 * (1.0 - math.pow_f64(pressure / 101325.0, exponent))
}
