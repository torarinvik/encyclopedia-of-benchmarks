from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS: Int64 = 998244353
comptime MAX_N = 4
comptime MAX_M = 8
comptime MAX_SIZE = 16
comptime MAX_INPUT = 35

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("power_projection_of_set_power_series")
fn power_projection_of_set_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n_value = input[0]
    let powers_value = input[1]
    if n_value < 0 or n_value > MAX_N or powers_value < 0 or powers_value > MAX_M:
        return -1
    let n = Int(n_value)
    let powers = Int(powers_value)
    let size = 1 << n
    if Int(length) != 2 + 2 * size:
        return -1

    var series = InlineArray[Int64, MAX_SIZE]()
    var weights = InlineArray[Int64, MAX_SIZE]()
    for mask in range(size):
        let a = input[2 + mask]
        let w = input[2 + size + mask]
        if a < 0 or a >= MODULUS or w < 0 or w >= MODULUS:
            return -1
        series[mask] = a
        weights[mask] = w

    let bytes = 8 * powers
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var current = InlineArray[Int64, MAX_SIZE]()
    var next = InlineArray[Int64, MAX_SIZE]()
    current[0] = 1
    for power in range(powers):
        var projection: Int64 = 0
        for mask in range(size):
            projection = (projection + weights[mask] * current[mask]) % MODULUS
        store_le(output, 8 * power, projection)
        if power + 1 == powers:
            break
        for mask in range(size):
            var total: Int64 = 0
            var subset = mask
            while True:
                total = (total + current[subset] * series[mask ^ subset]) % MODULUS
                if subset == 0:
                    break
                subset = (subset - 1) & mask
            next[mask] = total
        for mask in range(size):
            current[mask] = next[mask]
    return Int64(bytes)
