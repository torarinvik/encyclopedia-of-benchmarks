from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1244_polynomial_neighbor_sum")
fn tsvc_s1244_polynomial_neighbor_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 129: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 32 or length != c_size_t(1 + 4 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 4 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var d = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[1 + i]
        d[i] = input[1 + 3 * n + i]
    for i in range(n - 1):
        let b = input[1 + n + i]
        let c = input[1 + 2 * n + i]
        a[i] = b + c * c + b * b + c
        d[i] = a[i] + a[i + 1]
    for i in range(n):
        for byte in range(8):
            output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
            output[8 * (n + i) + byte] = UInt8((d[i] >> (8 * byte)) & 255)
    return Int64(2 * n)
