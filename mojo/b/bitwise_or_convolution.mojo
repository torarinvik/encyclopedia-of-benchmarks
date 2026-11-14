from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime OR_MAX_SIZE = 256
comptime OR_MAX_INPUT = 513
comptime OR_MOD: Int64 = 998244353

@export("bitwise_or_convolution")
fn bitwise_or_convolution(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > OR_MAX_INPUT: return -1
    let nv = input[0]
    if nv < 0 or nv > 8: return -1
    let n = Int(nv)
    let size = 1 << n
    if Int(length) != 1 + 2 * size: return -1
    for i in range(2 * size):
        let x = input[1 + i]
        if x < 0 or x >= OR_MOD: return -1
    let bytes = 8 * size
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < bytes: return -2
    var a = InlineArray[Int64, 256]()
    var b = InlineArray[Int64, 256]()
    for i in range(size):
        a[i] = input[1 + i]
        b[i] = input[1 + size + i]
    for bit in range(n):
        let bit_mask = 1 << bit
        for mask in range(size):
            if (mask & bit_mask) != 0:
                a[mask] = (a[mask] + a[mask ^ bit_mask]) % OR_MOD
                b[mask] = (b[mask] + b[mask ^ bit_mask]) % OR_MOD
    for i in range(size): a[i] = (a[i] * b[i]) % OR_MOD
    for bit in range(n):
        let bit_mask = 1 << bit
        for mask in range(size):
            if (mask & bit_mask) != 0:
                a[mask] -= a[mask ^ bit_mask]
                if a[mask] < 0: a[mask] += OR_MOD
    for i in range(size):
        let bits = bitcast[UInt64](a[i])
        for byte in range(8): output[i * 8 + byte] = UInt8((bits >> UInt(byte * 8)) & 255)
    return Int64(bytes)
