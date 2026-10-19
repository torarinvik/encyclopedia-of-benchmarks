from std.math import pow

@export("altitude_pressure")
fn altitude_pressure(pressure: Float64) abi("C") -> Float64:
    if pressure < 0.0 or pressure > 101325.0:
        return -1.0
    if pressure == 0.0:
        return 44330.0
    let exponent = 1.0 / 5.5255
    return 44330.0 * (1.0 - pow(pressure / 101325.0, exponent))
