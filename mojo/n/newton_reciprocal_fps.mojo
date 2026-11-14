from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS: Int64 = 998244353

fn power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result = Int64(1)
    while exponent > 0:
        if exponent % 2 != 0: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent //= 2
    return result

@export("newton_reciprocal_fps")
fn newton_reciprocal_fps(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let n = Int(input[0])
    if length != c_size_t(n + 1): return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= MODULUS: return -1
    if input[1] == 0: return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var inverse = InlineArray[Int64, 64](fill=0)
    inverse[0] = power(input[1], MODULUS - 2)
    var precision = 1
    while precision < n:
        var width = 2 * precision
        if width > n: width = n
        var correction = InlineArray[Int64, 64](fill=0)
        for i in range(width):
            var j = 0
            while j < precision and i + j < width:
                correction[i + j] = (correction[i + j] + input[i + 1] * inverse[j]) % MODULUS
                j += 1
        correction[0] = (2 + MODULUS - correction[0]) % MODULUS
        for i in range(1, width): correction[i] = (MODULUS - correction[i]) % MODULUS
        var next = InlineArray[Int64, 64](fill=0)
        for i in range(precision):
            for j in range(width - i):
                next[i + j] = (next[i + j] + inverse[i] * correction[j]) % MODULUS
        inverse = next
        precision = width
    for i in range(n):
        let bits = UInt64(inverse[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
