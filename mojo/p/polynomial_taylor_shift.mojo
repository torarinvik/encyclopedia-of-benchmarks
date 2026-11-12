from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime TAYLOR_MODULUS: Int64 = 998244353
comptime TAYLOR_MAX_N = 64
comptime TAYLOR_MAX_INPUT = 66

fn taylor_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("polynomial_taylor_shift")
fn polynomial_taylor_shift(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > TAYLOR_MAX_INPUT:
        return -1
    let n_value = input[0]
    let shift = input[1]
    if n_value < 1 or n_value > TAYLOR_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != n + 2 or shift < 0 or shift >= TAYLOR_MODULUS:
        return -1
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] >= TAYLOR_MODULUS:
            return -1

    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    var shifted = InlineArray[Int64, TAYLOR_MAX_N]()
    var processed = 0
    var source = n
    while source > 0:
        source -= 1
        var degree = processed
        while degree > 0:
            shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % TAYLOR_MODULUS
            degree -= 1
        shifted[0] = (shifted[0] * shift + input[source + 2]) % TAYLOR_MODULUS
        processed += 1
    for i in range(n):
        taylor_store_le(output, 8 * i, shifted[i])
    return Int64(bytes)
