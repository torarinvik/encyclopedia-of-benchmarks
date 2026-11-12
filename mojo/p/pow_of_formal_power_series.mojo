from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime POW_FPS_MODULUS: Int64 = 998244353
comptime POW_FPS_MAX_N = 32
comptime POW_FPS_MAX_INPUT = 34
comptime POW_FPS_MAX_EXPONENT: Int64 = 1000000000000000000

fn pow_fps_multiply(left: InlineArray[Int64, POW_FPS_MAX_N],
                    right: InlineArray[Int64, POW_FPS_MAX_N], n: Int,
                    inout product: InlineArray[Int64, POW_FPS_MAX_N]):
    for i in range(POW_FPS_MAX_N):
        product[i] = 0
    for i in range(n):
        for j in range(n - i):
            product[i + j] = (product[i + j] + left[i] * right[j]) % POW_FPS_MODULUS

fn pow_fps_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("pow_of_formal_power_series")
fn pow_of_formal_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > POW_FPS_MAX_INPUT:
        return -1
    let n_value = input[0]
    let exponent_input = input[1]
    if n_value < 1 or n_value > POW_FPS_MAX_N or exponent_input < 0 or exponent_input > POW_FPS_MAX_EXPONENT:
        return -1
    let n = Int(n_value)
    if Int(length) != n + 2:
        return -1
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] >= POW_FPS_MODULUS:
            return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2
    var result = InlineArray[Int64, POW_FPS_MAX_N]()
    var base = InlineArray[Int64, POW_FPS_MAX_N]()
    var temporary = InlineArray[Int64, POW_FPS_MAX_N]()
    result[0] = 1
    for i in range(n):
        base[i] = input[i + 2]
    var exponent = exponent_input
    while exponent > 0:
        if (exponent & 1) != 0:
            pow_fps_multiply(result, base, n, temporary)
            result = temporary
        exponent >>= 1
        if exponent > 0:
            pow_fps_multiply(base, base, n, temporary)
            base = temporary
    for i in range(n):
        pow_fps_store_le(output, 8 * i, result[i])
    return Int64(bytes)
