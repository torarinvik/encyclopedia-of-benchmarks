from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime GEOMETRIC_INTERPOLATION_MODULUS: Int64 = 998244353
comptime GEOMETRIC_INTERPOLATION_MAX_N = 8
comptime GEOMETRIC_INTERPOLATION_MAX_INPUT = 11

fn geometric_interpolation_normalize(value: Int64) -> Int64:
    let reduced = value % GEOMETRIC_INTERPOLATION_MODULUS
    if reduced < 0:
        return reduced + GEOMETRIC_INTERPOLATION_MODULUS
    return reduced

fn geometric_interpolation_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % GEOMETRIC_INTERPOLATION_MODULUS
        base = base * base % GEOMETRIC_INTERPOLATION_MODULUS
        exponent >>= 1
    return result

fn geometric_interpolation_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("polynomial_interpolation_on_geometric_sequence")
fn polynomial_interpolation_on_geometric_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > GEOMETRIC_INTERPOLATION_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > GEOMETRIC_INTERPOLATION_MAX_N:
        return -1
    let n = Int(n_value)
    let a = input[1]
    let r = input[2]
    if Int(length) != 3 + n or a < 0 or a >= GEOMETRIC_INTERPOLATION_MODULUS or r < 0 or r >= GEOMETRIC_INTERPOLATION_MODULUS:
        return -1

    var points = InlineArray[Int64, GEOMETRIC_INTERPOLATION_MAX_N]()
    var differences = InlineArray[Int64, GEOMETRIC_INTERPOLATION_MAX_N]()
    var newton = InlineArray[Int64, GEOMETRIC_INTERPOLATION_MAX_N]()
    var point = a
    for i in range(n):
        points[i] = point
        differences[i] = input[3 + i]
        if differences[i] < 0 or differences[i] >= GEOMETRIC_INTERPOLATION_MODULUS:
            return -1
        for j in range(i):
            if points[i] == points[j]:
                return -1
        point = point * r % GEOMETRIC_INTERPOLATION_MODULUS

    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    if n == 0:
        return 0
    newton[0] = differences[0]
    for order in range(1, n):
        let r_order = geometric_interpolation_power(r, Int64(order))
        var end = n
        while end > order:
            end -= 1
            let r_factor = geometric_interpolation_power(r, Int64(end - order))
            var denominator = a * r_factor % GEOMETRIC_INTERPOLATION_MODULUS
            denominator = denominator * (r_order - 1) % GEOMETRIC_INTERPOLATION_MODULUS
            let inverse = geometric_interpolation_power(
                geometric_interpolation_normalize(denominator), GEOMETRIC_INTERPOLATION_MODULUS - 2
            )
            differences[end] = geometric_interpolation_normalize(
                (differences[end] - differences[end - 1]) * inverse
            )
        newton[order] = differences[order]

    var coefficients = InlineArray[Int64, GEOMETRIC_INTERPOLATION_MAX_N]()
    var basis = InlineArray[Int64, GEOMETRIC_INTERPOLATION_MAX_N + 1]()
    basis[0] = 1
    var degree = 0
    for order in range(n):
        for k in range(degree + 1):
            coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % GEOMETRIC_INTERPOLATION_MODULUS
        if order + 1 == n:
            break
        var expanded = InlineArray[Int64, GEOMETRIC_INTERPOLATION_MAX_N + 1]()
        for k in range(degree + 1):
            expanded[k] = geometric_interpolation_normalize(expanded[k] - basis[k] * points[order])
            expanded[k + 1] = geometric_interpolation_normalize(expanded[k + 1] + basis[k])
        for k in range(degree + 2):
            basis[k] = expanded[k]
        degree += 1
    for i in range(n):
        geometric_interpolation_store_le(output, 8 * i, coefficients[i])
    return Int64(bytes)
