from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FPS_MODULUS: Int64 = 998244353
comptime FPS_MAX_N = 64
comptime FPS_MAX_INPUT = 66

fn fps_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("log_of_formal_power_series")
fn log_of_formal_power_series(
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
    if input[1] != 1:
        return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var integer_inverse = InlineArray[Int64, FPS_MAX_N]()
    var logarithm = InlineArray[Int64, FPS_MAX_N]()
    if n > 1:
        integer_inverse[1] = 1
    for k in range(2, n):
        let remainder = Int(FPS_MODULUS % Int64(k))
        integer_inverse[k] = FPS_MODULUS - (FPS_MODULUS / Int64(k)) * integer_inverse[remainder] % FPS_MODULUS
    for degree in range(1, n):
        var numerator = Int64(degree) * input[degree + 1] % FPS_MODULUS
        for i in range(1, degree):
            var term = Int64(i) * logarithm[i] % FPS_MODULUS
            term = term * input[degree - i + 1] % FPS_MODULUS
            numerator = (numerator - term) % FPS_MODULUS
            if numerator < 0:
                numerator += FPS_MODULUS
        logarithm[degree] = numerator * integer_inverse[degree] % FPS_MODULUS
    for i in range(n):
        fps_store_le(output, 8 * i, logarithm[i])
    return Int64(bytes)
