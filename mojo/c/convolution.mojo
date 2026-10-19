from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("convolution")
fn convolution(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 130: return -1
    let na = values[0]
    let nb = values[1]
    if na < 1 or na > 64 or nb < 1 or nb > 64 or length != na + nb + 2: return -1
    for i in range(na + nb):
        if values[2 + i] < -1000000 or values[2 + i] > 1000000: return -1
    let result_count = na + nb - 1
    let bytes = result_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < bytes: return -2
    for i in range(result_count):
        let start = i - (nb - 1) if i >= nb - 1 else 0
        let end = i if i < na else na - 1
        var sum: Int64 = 0
        for k in range(start, end + 1): sum += values[k + 2] * values[na + (i - k) + 2]
        let bits = UInt64(sum)
        for b in range(8): output[8 * i + b] = UInt8((bits >> (8 * b)) & 255)
    return bytes
