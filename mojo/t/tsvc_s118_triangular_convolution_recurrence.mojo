from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s118_triangular_convolution_recurrence")
fn tsvc_s118_triangular_convolution_recurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 74: return -1
    let n0 = input[0]; let passes = input[1]
    if n0 < 2 or n0 > 8 or passes < 1 or passes > 4: return -1
    let n = Int(n0)
    if length != c_size_t(2 + n + n * n): return -1
    for i in range(2, 2 + n + n * n):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    for i in range(n): a[i] = input[2 + i]
    for _ in range(Int(passes)):
        for i in range(1, n):
            for j in range(i): a[i] += input[2 + n + j * n + i] * a[i - j - 1]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return n0
