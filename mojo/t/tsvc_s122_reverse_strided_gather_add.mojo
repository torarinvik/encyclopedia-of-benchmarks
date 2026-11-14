from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s122_reverse_strided_gather_add")
fn tsvc_s122_reverse_strided_gather_add(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 67: return -1
    let n0 = input[0]
    let start0 = input[1]
    let stride0 = input[2]
    if n0 < 1 or n0 > 32 or start0 < 1 or start0 > n0 or stride0 < 1 or stride0 > n0: return -1
    if length != c_size_t(3 + 2 * n0): return -1
    let n = Int(n0)
    for i in range(3, 3 + 2 * n):
        if input[i] < -100 or input[i] > 100: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[3 + i]
    var destination = Int(start0) - 1
    var count = 0
    while destination < n:
        a[destination] += input[3 + n + n - 1 - count]
        destination += Int(stride0)
        count += 1
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(n)
