module altitude_pressure

import math

// Estimate altitude from pressure using the pinned source formula.
@[export: 'altitude_pressure']
pub fn altitude_pressure(pressure f64) f64 {
    if pressure < 0.0 || pressure > 101325.0 { return -1.0 }
    if pressure == 0.0 { return 44330.0 }
    exponent := 1.0 / 5.5255
    return 44330.0 * (1.0 - math.pow(pressure / 101325.0, exponent))
}
