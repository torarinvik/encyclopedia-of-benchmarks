from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FPS_MODULUS: Int64 = 998244353
comptime FPS_MAX_N = 64
comptime FPS_MAX_INPUT = 66

fn fps_power_mod(base_input: Int64, exponent_input: Int64) -> Int64:
    var base = base_input
    var exponent = exponent_input
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = result * base % FPS_MODULUS
        base = base * base % FPS_MODULUS
        exponent >>= 1
    return result

fn fps_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("inv_of_formal_power_series")
fn inv_of_formal_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > FPS_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > FPS_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != n + 1:
        return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= FPS_MODULUS:
            return -1
    if input[1] == 0:
        return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var inverse = InlineArray[Int64, FPS_MAX_N]()
    let inverse_constant = fps_power_mod(input[1], FPS_MODULUS - 2)
    inverse[0] = inverse_constant
    for degree in range(1, n):
        var sum: Int64 = 0
        for i in range(1, degree + 1):
            sum = (sum + input[i + 1] * inverse[degree - i]) % FPS_MODULUS
        inverse[degree] = (FPS_MODULUS - inverse_constant * sum % FPS_MODULUS) % FPS_MODULUS
    for i in range(n):
        fps_store_le(output, 8 * i, inverse[i])
    return Int64(bytes)
