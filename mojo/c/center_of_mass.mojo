from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn round_two_python(value: Float64) -> Float64:
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
    let numerator = significand * 100
    let shift = 53 - exponent
    var cents: UInt64 = 0
    if shift < 0:
        cents = numerator << UInt64(-shift)
    elif shift == 0:
        cents = numerator
    elif shift < 64:
        let denominator = UInt64(1) << UInt64(shift)
        cents = numerator >> UInt64(shift)
        let remainder = numerator & (denominator - 1)
        let half = denominator >> 1
        if remainder > half or (remainder == half and (cents & 1) != 0): cents += 1
    let rounded = Float64(cents) / 100.0
    return -rounded if negative else rounded

@export("center_of_mass")
fn center_of_mass(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258: return -1.0e300
    let selector = values[0]
    let count = values[1]
    if selector < 0 or selector > 2 or count < 1 or count > 64 or length != 2 + 4 * count: return -1.0e300
    for i in range(count):
        let offset = 2 + 4 * i
        for coordinate in range(3):
            if values[offset + coordinate] < -1000000 or values[offset + coordinate] > 1000000: return -1.0e300
        if values[offset + 3] < 1 or values[offset + 3] > 1000000: return -1.0e300
    var total_mass: Float64 = 0.0
    for i in range(count): total_mass += Float64(values[2 + 4 * i + 3]) / 1000.0
    var weighted_coordinate: Float64 = 0.0
    for i in range(count):
        let offset = 2 + 4 * i
        let coordinate = Float64(values[offset + selector]) / 1000.0
        let mass = Float64(values[offset + 3]) / 1000.0
        weighted_coordinate += coordinate * mass
    return round_two_python(weighted_coordinate / total_mass)
