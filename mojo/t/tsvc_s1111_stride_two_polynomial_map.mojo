from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1111_stride_two_polynomial_map")
fn tsvc_s1111_stride_two_polynomial_map(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 161: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 32 or length != c_size_t(1 + 5 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 5 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * n): return -2
    var a = List[Int64](length=2 * n, fill=0)
    for i in range(2 * n):
        a[i] = input[1 + i]
    for i in range(n):
        let b = input[1 + 2 * n + i]
        let c = input[1 + 3 * n + i]
        let d = input[1 + 4 * n + i]
        a[2 * i] = c * b + d * b + c * c + d * b + d * c
    for i in range(2 * n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(2 * n)
