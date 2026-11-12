from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FPS_MODULUS: Int64 = 998244353
comptime FPS_MAX_N = 16
comptime FPS_MAX_INPUT = 34

fn fps_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("composition_of_formal_power_series")
fn composition_of_formal_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > FPS_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > FPS_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != 1 + 2 * n:
        return -1
    for i in range(2 * n):
        if input[i + 1] < 0 or input[i + 1] >= FPS_MODULUS:
            return -1
    if input[1 + n] != 0:
        return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var composed = InlineArray[Int64, FPS_MAX_N]()
    var outer = n
    while outer > 0:
        var bound = n
        while bound > 1:
            let degree = bound - 1
            var sum: Int64 = 0
            for inner_degree in range(1, degree + 1):
                sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % FPS_MODULUS
            composed[degree] = sum
            bound -= 1
        composed[0] = input[outer]
        outer -= 1
    for i in range(n):
        fps_store_le(output, 8 * i, composed[i])
    return Int64(bytes)
