from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS: Int64 = 998244353
comptime MAX_COEFFICIENTS = 8
comptime MAX_N = 4
comptime MAX_SIZE = 16
comptime MAX_INPUT = 27

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("polynomial_composite_set_power_series")
fn polynomial_composite_set_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let count_value = input[0]
    let n_value = input[1]
    if count_value < 0 or count_value > MAX_COEFFICIENTS or n_value < 0 or n_value > MAX_N:
        return -1
    let count = Int(count_value)
    let n = Int(n_value)
    let size = 1 << n
    if Int(length) != 2 + count + size:
        return -1
    for index in range(count + size):
        if input[2 + index] < 0 or input[2 + index] >= MODULUS:
            return -1

    let bytes = 8 * size
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2

    var series = InlineArray[Int64, MAX_SIZE]()
    var result = InlineArray[Int64, MAX_SIZE]()
    var temporary = InlineArray[Int64, MAX_SIZE]()
    for mask in range(size):
        series[mask] = input[2 + count + mask]

    var degree = count
    while degree > 0:
        for mask in range(size):
            var total: Int64 = 0
            var subset = mask
            while True:
                total = (total + result[subset] * series[mask ^ subset]) % MODULUS
                if subset == 0:
                    break
                subset = (subset - 1) & mask
            temporary[mask] = total
        temporary[0] = (temporary[0] + input[1 + degree]) % MODULUS
        for mask in range(size):
            result[mask] = temporary[mask]
        degree -= 1

    for mask in range(size):
        store_le(output, 8 * mask, result[mask])
    return Int64(bytes)
