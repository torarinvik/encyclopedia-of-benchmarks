from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime M2_MAX_N = 5
comptime M2_MAX_P = 32
comptime M2_MAX_INPUT = 66
comptime M2_MAX_OUTPUT = 256
comptime M2_MOD: Int64 = 998244353

@export("mul_mod2n_convolution")
fn mul_mod2n_convolution(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > M2_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > M2_MAX_N:
        return -1
    let p = 1 << Int(n_value)
    if Int(length) != 1 + 2 * p:
        return -1
    for i in range(1, Int(length)):
        if input[i] < 0 or input[i] >= M2_MOD:
            return -1
    let bytes = 8 * p
    if bytes > M2_MAX_OUTPUT:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var a = InlineArray[Int64, 32]()
    var b = InlineArray[Int64, 32]()
    var result = InlineArray[Int64, 32]()
    for i in range(p):
        a[i] = input[1 + i]
        b[i] = input[1 + p + i]
    let mask = p - 1
    for i in range(p):
        for j in range(p):
            let k = (i * j) & mask
            result[k] = (result[k] + a[i] * b[j]) % M2_MOD
    for i in range(p):
        let bits = bitcast[UInt64](result[i])
        for byte in range(8):
            output[i * 8 + byte] = UInt8((bits >> UInt(byte * 8)) & 255)
    return Int64(bytes)
