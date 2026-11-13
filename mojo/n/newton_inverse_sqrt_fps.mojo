from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS: Int64 = 998244353
comptime HALF: Int64 = 499122177

fn multiply(left: InlineArray[Int64, 64], right: InlineArray[Int64, 64], width: Int) -> InlineArray[Int64, 64]:
    var result = InlineArray[Int64, 64](0)
    for i in range(width):
        for j in range(width - i):
            result[i + j] = (result[i + j] + left[i] * right[j]) % MODULUS
    return result

@export("newton_inverse_sqrt_fps")
fn newton_inverse_sqrt_fps(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let n = Int(input[0])
    if length != c_size_t(n + 1): return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= MODULUS: return -1
    if input[1] != 1: return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var f = InlineArray[Int64, 64](0)
    var inverse = InlineArray[Int64, 64](0)
    for i in range(n): f[i] = input[i + 1]
    inverse[0] = 1
    var precision = 1
    while precision < n:
        var width = 2 * precision
        if width > n: width = n
        let square = multiply(inverse, inverse, width)
        let product = multiply(f, square, width)
        var correction = InlineArray[Int64, 64](0)
        correction[0] = (3 + MODULUS - product[0]) * HALF % MODULUS
        for i in range(1, width): correction[i] = (MODULUS - product[i]) * HALF % MODULUS
        inverse = multiply(inverse, correction, width)
        precision = width
    for i in range(n):
        let bits = UInt64(inverse[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
