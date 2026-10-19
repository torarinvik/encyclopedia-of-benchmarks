from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import exp

fn round_three_python(value: Float64) -> Float64:
    if value == 0.0: return value
    let negative = value < 0.0
    var normalized = -value if negative else value
    var exponent: Int64 = 0
    while normalized >= 1.0:
        normalized *= 0.5
        exponent += 1
    while normalized < 0.5:
        normalized *= 2.0
        exponent -= 1
    let significand = UInt64(normalized * 9007199254740992.0)
    let numerator = significand * 1000
    let shift = 53 - exponent
    var milliunits: UInt64 = 0
    if shift < 0:
        milliunits = numerator << UInt64(-shift)
    elif shift == 0:
        milliunits = numerator
    elif shift < 64:
        let denominator = UInt64(1) << UInt64(shift)
        milliunits = numerator >> UInt64(shift)
        let remainder = numerator & (denominator - 1)
        let half = denominator >> 1
        if remainder > half or (remainder == half and (milliunits & 1) != 0): milliunits += 1
    let rounded = Float64(milliunits) / 1000.0
    return -rounded if negative else rounded

@export("charging_inductor")
fn charging_inductor(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1.0e300
    let voltage_micro = values[0]
    let resistance_micro = values[1]
    let inductance_micro = values[2]
    let time_micro = values[3]
    if voltage_micro < 1 or voltage_micro > 1000000000000 or resistance_micro < 10000 or resistance_micro > 1000000000000000 or inductance_micro < 1 or inductance_micro > 1000000000000 or time_micro < -1000000000000 or time_micro > 1000000000000: return -1.0e300
    let source_voltage = Float64(voltage_micro) / 1000000.0
    let resistance = Float64(resistance_micro) / 1000000.0
    let inductance = Float64(inductance_micro) / 1000000.0
    let time_sec = Float64(time_micro) / 1000000.0
    let exponent = (-time_sec * resistance) / inductance
    if exponent > 10.0: return -1.0e300
    return round_three_python(source_voltage / resistance * (1.0 - exp(exponent)))
