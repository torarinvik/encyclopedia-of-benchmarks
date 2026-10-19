from std.ffi import c_size_t
from std.math import abs, pow, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime INVALID_RESULT: Float64 = -1e300
comptime MAX_PHYSICAL: Int64 = 1_000_000_000_000_000
comptime MAX_FLUX_RATE: Int64 = 1_000_000_000_000_000_000
comptime MIN_CONSTANT: Int64 = 1_000_000
comptime MAX_CONSTANT: Int64 = 1_000_000_000_000_000
comptime PHYSICAL_SCALE: Float64 = 1e12
comptime CONSTANT_SCALE: Float64 = 1e18
comptime PI: Float64 = 3.14159265358979323846264338327950288
comptime EPSILON_DEFAULT: Float64 = 8.8541878128e-12
comptime MU_DEFAULT: Float64 = 4.0 * PI * 1e-7


fn in_range(value: Int64, limit: Int64) -> Bool:
    return value >= -limit and value <= limit


fn valid_constant(raw: Int64) -> Bool:
    return raw == 0 or (raw >= MIN_CONSTANT and raw <= MAX_CONSTANT)


fn decode_constant(raw: Int64, fallback: Float64) -> Float64:
    if raw == 0:
        return fallback
    return Float64(raw) / CONSTANT_SCALE


fn law_result(actual: Float64, expected: Float64) -> Float64:
    var tolerance = Float64(1e-10)
    if expected != 0.0:
        tolerance = 0.01 * abs(expected)
    if abs(actual - expected) <= tolerance:
        return 1.0
    return 0.0


@export("maxwells_equations")
fn maxwells_equations(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 7:
        return INVALID_RESULT
    let operation = input[0]
    if operation == 0:
        if length != 5:
            return INVALID_RESULT
        let field = input[1]
        let area = input[2]
        let charge = input[3]
        let epsilon_raw = input[4]
        if (
            not in_range(field, MAX_PHYSICAL) or area < 0 or area > MAX_PHYSICAL
            or not in_range(charge, MAX_PHYSICAL) or not valid_constant(epsilon_raw)
        ):
            return INVALID_RESULT
        let epsilon = decode_constant(epsilon_raw, EPSILON_DEFAULT)
        let electric_flux = (Float64(field) / PHYSICAL_SCALE) * (Float64(area) / PHYSICAL_SCALE)
        let expected_flux = (Float64(charge) / PHYSICAL_SCALE) / epsilon
        return law_result(electric_flux, expected_flux)
    elif operation == 1:
        if length != 3 or not in_range(input[1], MAX_PHYSICAL) or not in_range(input[2], MAX_PHYSICAL):
            return INVALID_RESULT
        let circulation = Float64(input[1]) / PHYSICAL_SCALE
        let expected = -(Float64(input[2]) / PHYSICAL_SCALE)
        return law_result(circulation, expected)
    elif operation == 2:
        if (
            length != 6 or not in_range(input[1], MAX_PHYSICAL)
            or not in_range(input[2], MAX_PHYSICAL)
            or not in_range(input[3], MAX_FLUX_RATE)
            or not valid_constant(input[4]) or not valid_constant(input[5])
        ):
            return INVALID_RESULT
        let mu = decode_constant(input[4], MU_DEFAULT)
        let epsilon = decode_constant(input[5], EPSILON_DEFAULT)
        let displacement_current = epsilon * (Float64(input[3]) / 1e6)
        let total_current = (Float64(input[2]) / PHYSICAL_SCALE) + displacement_current
        let expected = mu * total_current
        return law_result(Float64(input[1]) / PHYSICAL_SCALE, expected)
    elif operation == 3 or operation == 4:
        if length != 3 or not valid_constant(input[1]) or not valid_constant(input[2]):
            return INVALID_RESULT
        let mu = decode_constant(input[1], MU_DEFAULT)
        let epsilon = decode_constant(input[2], EPSILON_DEFAULT)
        if operation == 3:
            return 1.0 / sqrt(mu * epsilon)
        return sqrt(mu / epsilon)
    elif operation == 5:
        if length != 4 or not in_range(input[1], MAX_PHYSICAL) or not in_range(input[2], MAX_PHYSICAL) or not valid_constant(input[3]):
            return INVALID_RESULT
        let mu = decode_constant(input[3], MU_DEFAULT)
        return ((Float64(input[1]) / PHYSICAL_SCALE) * (Float64(input[2]) / PHYSICAL_SCALE)) / mu
    elif operation == 6:
        if length != 5 or not in_range(input[1], MAX_PHYSICAL) or not in_range(input[2], MAX_PHYSICAL) or not valid_constant(input[3]) or not valid_constant(input[4]):
            return INVALID_RESULT
        let epsilon = decode_constant(input[3], EPSILON_DEFAULT)
        let mu = decode_constant(input[4], MU_DEFAULT)
        let electric_energy = 0.5 * epsilon * pow(Float64(input[1]) / PHYSICAL_SCALE, 2.0)
        let magnetic_energy = 0.5 * pow(Float64(input[2]) / PHYSICAL_SCALE, 2.0) / mu
        return electric_energy + magnetic_energy
    return INVALID_RESULT
