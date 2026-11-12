from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FPS_MODULUS: Int64 = 998244353
comptime FPS_MIN_N = 2
comptime FPS_MAX_N = 16
comptime FPS_MAX_INPUT = 18

fn fps_mod_pow(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value % FPS_MODULUS
    var exponent = exponent_value
    var result = Int64(1)
    while exponent > 0:
        if exponent % 2 != 0: result = result * base % FPS_MODULUS
        base = base * base % FPS_MODULUS
        exponent //= 2
    return result

fn fps_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("compositional_inverse_of_formal_power_series")
fn compositional_inverse_of_formal_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < FPS_MIN_N + 1 or length > FPS_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < FPS_MIN_N or n_value > FPS_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != n + 1:
        return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] >= FPS_MODULUS:
            return -1
    if input[1] != 0 or input[2] == 0:
        return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var powers = InlineArray[Int64, FPS_MAX_N * FPS_MAX_N]()
    var inverse_series = InlineArray[Int64, FPS_MAX_N]()
    let inverse_linear = fps_mod_pow(input[2], FPS_MODULUS - 2)
    inverse_series[1] = inverse_linear
    powers[FPS_MAX_N + 1] = inverse_linear
    for degree in range(2, n):
        for power in range(2, degree + 1):
            var coefficient = Int64(0)
            for split in range(1, degree):
                coefficient = (coefficient + powers[(power - 1) * FPS_MAX_N + degree - split] *
                    inverse_series[split]) % FPS_MODULUS
            powers[power * FPS_MAX_N + degree] = coefficient
        var composed_coefficient = Int64(0)
        for power in range(2, degree + 1):
            composed_coefficient = (composed_coefficient + input[power + 1] *
                powers[power * FPS_MAX_N + degree]) % FPS_MODULUS
        inverse_series[degree] = (FPS_MODULUS - composed_coefficient) * inverse_linear % FPS_MODULUS
        powers[FPS_MAX_N + degree] = inverse_series[degree]
    for i in range(n): fps_store_le(output, 8 * i, inverse_series[i])
    return Int64(bytes)
