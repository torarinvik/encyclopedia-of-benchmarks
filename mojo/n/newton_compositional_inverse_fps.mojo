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

fn multiply(left: InlineArray[Int64, 16], right: InlineArray[Int64, 16], width: Int) -> InlineArray[Int64, 16]:
    var result = InlineArray[Int64, 16](fill=0)
    for i in range(width):
        for j in range(width - i):
            result[i + j] = (result[i + j] + left[i] * right[j]) % MODULUS
    return result

fn compose(outer: InlineArray[Int64, 16], inner: InlineArray[Int64, 16], width: Int) -> InlineArray[Int64, 16]:
    var result = InlineArray[Int64, 16](fill=0)
    var degree = width
    while degree > 0:
        degree -= 1
        result = multiply(result, inner, width)
        result[0] = (result[0] + outer[degree]) % MODULUS
    return result

@export("newton_compositional_inverse_fps")
fn newton_compositional_inverse_fps(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 18: return -1
    if input[0] < 2 or input[0] > 16: return -1
    let n = Int(input[0])
    if length != c_size_t(n + 1): return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= MODULUS: return -1
    if input[1] != 0 or input[2] == 0: return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var f = InlineArray[Int64, 16](fill=0)
    var derivative = InlineArray[Int64, 16](fill=0)
    var inverse = InlineArray[Int64, 16](fill=0)
    for i in range(n): f[i] = input[i + 1]
    for i in range(1, n): derivative[i - 1] = Int64(i) * f[i] % MODULUS
    let inverse_linear = power(f[1], MODULUS - 2)
    inverse[1] = inverse_linear
    var precision = 2
    while precision < n:
        var width = 2 * precision
        if width > n: width = n
        var residual = compose(f, inverse, width)
        residual[1] = (residual[1] + MODULUS - 1) % MODULUS
        let slope = compose(derivative, inverse, width)
        var reciprocal = InlineArray[Int64, 16](fill=0)
        reciprocal[0] = inverse_linear
        for i in range(1, width):
            var sum = Int64(0)
            for j in range(1, i + 1): sum = (sum + slope[j] * reciprocal[i - j]) % MODULUS
            reciprocal[i] = (MODULUS - sum) * inverse_linear % MODULUS
        let correction = multiply(residual, reciprocal, width)
        for i in range(width): inverse[i] = (inverse[i] + MODULUS - correction[i]) % MODULUS
        precision = width
    for i in range(n):
        let bits = UInt64(inverse[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
