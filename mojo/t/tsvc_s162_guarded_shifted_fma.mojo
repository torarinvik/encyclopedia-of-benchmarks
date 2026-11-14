from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s162_guarded_shifted_fma")
fn tsvc_s162_guarded_shifted_fma(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 194: return -1
    let n0 = input[0]
    let guard = input[1]
    if n0 < 1 or n0 > 64 or guard < 0 or guard > 1 or length != c_size_t(2 + 3 * n0): return -1
    let n = Int(n0)
    for i in range(2, 2 + 3 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[2 + i]
    if guard == 1:
        for i in range(n - 1):
            a[i] = a[i + 1] + input[2 + n + i] * input[2 + 2 * n + i]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(n)
