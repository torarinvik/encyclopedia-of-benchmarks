from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s115_upper_triangular_saxpy_elimination")
fn tsvc_s115_upper_triangular_saxpy_elimination(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 58: return -1
    let n0 = input[0]; let passes = input[1]
    if n0 < 2 or n0 > 7 or passes < 1 or passes > 3: return -1
    let n = Int(n0)
    if length != c_size_t(2 + n + n * n): return -1
    for i in range(2, 2 + n + n * n):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    for i in range(n): a[i] = input[2 + i]
    for _ in range(Int(passes)):
        for j in range(n):
            for i in range(j + 1, n): a[i] -= input[2 + n + j * n + i] * a[j]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return n0
