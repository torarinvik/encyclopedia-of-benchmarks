from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS: Int64 = 998244353
comptime MAX_N = 5
comptime MAX_SIZE = 32
comptime MAX_INPUT = 33

fn subset_size(mut mask: Int) -> Int:
    var count = 0
    while mask != 0:
        count += mask & 1
        mask >>= 1
    return count

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("exp_of_set_power_series")
fn exp_of_set_power_series(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 0 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    let size = 1 << n
    if Int(length) != 1 + size or input[1] != 0:
        return -1
    for mask in range(size):
        if input[1 + mask] < 0 or input[1 + mask] >= MODULUS:
            return -1

    let bytes = 8 * size
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes:
        return -2

    var inverse = InlineArray[Int64, MAX_N + 1]()
    var values = InlineArray[Int64, MAX_SIZE]()
    if n > 0:
        inverse[1] = 1
    for k in range(2, n + 1):
        let remainder = Int(MODULUS % Int64(k))
        inverse[k] = MODULUS - (MODULUS / Int64(k)) * inverse[remainder] % MODULUS
    values[0] = 1
    for mask in range(1, size):
        var total: Int64 = 0
        var subset = mask
        while subset != 0:
            var term = Int64(subset_size(subset)) * input[1 + subset] % MODULUS
            term = term * values[mask ^ subset] % MODULUS
            total = (total + term) % MODULUS
            subset = (subset - 1) & mask
        values[mask] = total * inverse[subset_size(mask)] % MODULUS
    for mask in range(size):
        store_le(output, 8 * mask, values[mask])
    return Int64(bytes)
