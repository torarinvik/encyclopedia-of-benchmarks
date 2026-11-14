from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn allroots_newton(lower: Float64, upper: Float64) -> Float64:
    var previous = min(lower, upper)
    var current = (lower + upper) / 2.0
    var iterations = 0
    while abs(current - previous) / abs(current) > 5.0e-6 and iterations <= 40:
        previous = current
        var value: Float64 = 1.0
        var slope: Float64 = 1.0
        value = current * value - 1.0
        slope = current * slope + value
        value = current * value - 4.0
        slope = current * slope + value
        value = current * value + 4.0
        current -= value / slope
        iterations += 1
    return current

@export("prolangs_c_allroots")
fn prolangs_c_allroots(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1
    if input[0] != 4 or input[1] != -4 or input[2] != -1 or input[3] != 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    let first = allroots_newton(-11.0, 10.0)
    let a: Float64 = 1.0
    let b = first - 1.0
    let c = b * first - 4.0
    let discriminant = b * b - 4.0 * a * c
    let plus = (-b + sqrt(discriminant)) / (2.0 * a)
    let minus = (-b - sqrt(discriminant)) / (2.0 * a)
    var roots = InlineArray[Float64, 3](fill=0.0)
    roots[0] = first
    roots[1] = allroots_newton(plus - 0.5, plus + 0.5)
    roots[2] = allroots_newton(minus - 0.5, minus + 0.5)
    for i in range(3):
        var bits = bitcast[UInt64](roots[i])
        for b in range(8):
            output[8 * i + b] = UInt8(bits & 255)
            bits >>= 8
    return 24
