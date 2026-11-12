from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime INTERPOLATION_MODULUS: Int64 = 998244353
comptime INTERPOLATION_MAX_N = 12
comptime INTERPOLATION_MAX_INPUT = 25

fn interpolation_normalize(value: Int64) -> Int64:
    let reduced = value % INTERPOLATION_MODULUS
    if reduced < 0:
        return reduced + INTERPOLATION_MODULUS
    return reduced

fn interpolation_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % INTERPOLATION_MODULUS
        base = base * base % INTERPOLATION_MODULUS
        exponent >>= 1
    return result

fn interpolation_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("polynomial_interpolation")
fn polynomial_interpolation(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > INTERPOLATION_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > INTERPOLATION_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != 1 + 2 * n:
        return -1
    for i in range(n):
        let xi = input[1 + i]
        let yi = input[1 + n + i]
        if xi < 0 or xi >= INTERPOLATION_MODULUS or yi < 0 or yi >= INTERPOLATION_MODULUS:
            return -1
        for j in range(i):
            if xi == input[1 + j]:
                return -1

    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    var result = InlineArray[Int64, INTERPOLATION_MAX_N]()
    for i in range(n):
        var basis = InlineArray[Int64, INTERPOLATION_MAX_N + 1]()
        basis[0] = 1
        var degree = 0
        var denominator: Int64 = 1
        for j in range(n):
            if j == i:
                continue
            let xj = input[1 + j]
            denominator = denominator * (input[1 + i] - xj) % INTERPOLATION_MODULUS
            var expanded = InlineArray[Int64, INTERPOLATION_MAX_N + 1]()
            for k in range(degree + 1):
                expanded[k] = interpolation_normalize(expanded[k] - basis[k] * xj)
                expanded[k + 1] = interpolation_normalize(expanded[k + 1] + basis[k])
            for k in range(degree + 2):
                basis[k] = expanded[k]
            degree += 1
        let scale = input[1 + n + i] * interpolation_power(
            interpolation_normalize(denominator), INTERPOLATION_MODULUS - 2
        ) % INTERPOLATION_MODULUS
        for k in range(n):
            result[k] = (result[k] + scale * basis[k]) % INTERPOLATION_MODULUS
    for i in range(n):
        interpolation_store_le(output, 8 * i, result[i])
    return Int64(bytes)
