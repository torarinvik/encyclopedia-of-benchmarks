from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s261_shifted_cross_array_update")
fn tsvc_s261_shifted_cross_array_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 257: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 64 or length != c_size_t(1 + 4 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 4 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var c = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[1 + i]
        c[i] = input[1 + 2 * n + i]
    for i in range(1, n):
        a[i] = a[i] + input[1 + n + i] + c[i - 1]
        c[i] = c[i] * input[1 + 3 * n + i]
    for i in range(n):
        for byte in range(8):
            output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
            output[8 * (n + i) + byte] = UInt8((c[i] >> (8 * byte)) & 255)
    return Int64(2 * n)
