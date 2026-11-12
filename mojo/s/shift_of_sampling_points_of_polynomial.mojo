from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime SHIFT_MODULUS: Int64 = 998244353
comptime SHIFT_MAX_N = 16
comptime SHIFT_MAX_M = 16
comptime SHIFT_MAX_INPUT = 20

fn shift_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = result * base % SHIFT_MODULUS
        base = base * base % SHIFT_MODULUS
        exponent >>= 1
    return result

fn shift_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("shift_of_sampling_points_of_polynomial")
fn shift_of_sampling_points_of_polynomial(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > SHIFT_MAX_INPUT: return -1
    let n_value = input[0]
    let m_value = input[1]
    let start = input[2]
    if n_value < 1 or n_value > SHIFT_MAX_N or m_value < 1 or m_value > SHIFT_MAX_M: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != n + 3 or start < 0 or start >= SHIFT_MODULUS: return -1
    for i in range(n):
        if input[i + 3] < 0 or input[i + 3] >= SHIFT_MODULUS: return -1

    let bytes = 8 * m
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    var differences = InlineArray[Int64, SHIFT_MAX_N]()
    var newton = InlineArray[Int64, SHIFT_MAX_N]()
    var factorial = InlineArray[Int64, SHIFT_MAX_N]()
    var inverse_factorial = InlineArray[Int64, SHIFT_MAX_N]()
    for i in range(n): differences[i] = input[i + 3]
    factorial[0] = 1
    for k in range(1, n): factorial[k] = factorial[k - 1] * Int64(k) % SHIFT_MODULUS
    inverse_factorial[n - 1] = shift_mod_pow(factorial[n - 1], SHIFT_MODULUS - 2)
    for k in range(n - 1, 0, -1): inverse_factorial[k - 1] = inverse_factorial[k] * Int64(k) % SHIFT_MODULUS
    for k in range(n):
        newton[k] = differences[0] * inverse_factorial[k] % SHIFT_MODULUS
        for i in range(n - k - 1):
            differences[i] = differences[i + 1] - differences[i]
            if differences[i] < 0: differences[i] += SHIFT_MODULUS

    for offset in range(m):
        var x = start + Int64(offset)
        if x >= SHIFT_MODULUS: x -= SHIFT_MODULUS
        var basis: Int64 = 1
        var value: Int64 = 0
        for k in range(n):
            value = (value + newton[k] * basis) % SHIFT_MODULUS
            var factor = x - Int64(k)
            if factor < 0: factor += SHIFT_MODULUS
            basis = basis * factor % SHIFT_MODULUS
        shift_store_le(output, 8 * offset, value)
    return Int64(bytes)
