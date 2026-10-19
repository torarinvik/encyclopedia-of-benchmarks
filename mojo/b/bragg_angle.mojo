from std.ffi import c_size_t
from std.math import asin, floor
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime PI: Float64 = 3.141592653589793238462643383279502884

fn bragg_round_one(value: Float64) -> Float64:
    let scaled = value * 10.0; let lo = floor(scaled); let frac = scaled - lo; var rounded = Int64(lo)
    if frac > 0.5 or (frac == 0.5 and rounded % 2 != 0): rounded += 1
    return Float64(rounded) / 10.0

@export("bragg_angle")
fn bragg_angle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1.0e300
    let distance = input[0]; let order = input[1]; let wavelength = input[2]
    if distance < 1 or distance > 1_000_000 or order < -1000 or order > 1000 or wavelength < 0 or wavelength > 1_000_000: return -1.0e300
    let sine = (Float64(order) * Float64(wavelength)) / (2.0 * Float64(distance))
    if sine < -1.0 or sine > 1.0: return -1.0e300
    return bragg_round_one(asin(sine) * (180.0 / PI))
