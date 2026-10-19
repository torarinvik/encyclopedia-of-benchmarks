from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn boyles_rounded_milli(numerator: Int64, denominator: Int64) -> Int64:
    let scaled = numerator * 1000; var q = scaled // denominator; let r = scaled % denominator
    if 2 * r > denominator or (2 * r == denominator and q % 2 != 0): q += 1
    return q

@export("boyles_law")
fn boyles_law(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 4: return -1.0e300
    let target = input[0]; let a = input[1]; let b = input[2]; let c = input[3]
    if target < 0 or target > 3 or a < 1 or a > 1000 or b < 1 or b > 1000 or c < 1 or c > 1000: return -1.0e300
    var num: Int64 = 0; var den: Int64 = 1
    if target == 0: num = c * a; den = b
    elif target == 1: num = b * a; den = c
    elif target == 2: num = c * b; den = a
    else: num = c * a; den = b
    return Float64(boyles_rounded_milli(num, den)) / 1000.0
