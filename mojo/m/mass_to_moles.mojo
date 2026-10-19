from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("mass_to_moles")
fn mass_to_moles(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Float64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 2: return -1.0e300
    let mass = v[0]; let molar = v[1]
    if mass < 0 or mass > 1000 or molar < 1 or molar > 1000: return -1.0e300
    if mass == 0: return 0.0
    let quotient = Float64(mass) / Float64(molar)
    let bits = bitcast[UInt64](quotient)
    let exponent_field = Int((bits >> 52) & 0x7ff)
    let significand = (bits & 0x000fffffffffffff) | 0x0010000000000000
    let binary_power = exponent_field - 1023 - 52
    if binary_power >= 0 or -binary_power >= 64: return -1.0e300
    let numerator = significand * UInt64(100)
    let denominator = UInt64(1) << UInt(-binary_power)
    var cents = numerator / denominator
    let remainder = numerator % denominator
    let twice = remainder * UInt64(2)
    if twice > denominator or (twice == denominator and (cents & 1) != 0): cents += 1
    return Float64(cents) / 100.0
