from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s128_strided_coupled_update")
fn tsvc_s128_strided_coupled_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 81: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 16 or length != c_size_t(1 + 5 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 5 * n):
        if input[i] < -100 or input[i] > 100: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(24 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var b = List[Int64](length=2 * n, fill=0)
    for i in range(2 * n):
        b[i] = input[1 + i]
    for i in range(n):
        let k = 2 * i
        a[i] = b[k] - input[1 + 4 * n + i]
        b[k] = a[i] + input[1 + 2 * n + k]
    for i in range(3 * n):
        var value: Int64 = 0
        if i < n:
            value = a[i]
        else:
            value = b[i - n]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(3 * n)
