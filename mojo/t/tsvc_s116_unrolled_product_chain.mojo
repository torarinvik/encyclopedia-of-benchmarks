from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s116_unrolled_product_chain")
fn tsvc_s116_unrolled_product_chain(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 23: return -1
    let n0 = input[0]
    let passes = input[1]
    if n0 < 6 or n0 > 21 or (n0 - 1) % 5 != 0 or passes < 1 or passes > 4: return -1
    if length != c_size_t(2 + n0): return -1
    let n = Int(n0)
    for i in range(n):
        if input[2 + i] != -1 and input[2 + i] != 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[2 + i]
    for _ in range(Int(passes)):
        var i = 0
        while i < n - 5:
            a[i] = a[i + 1] * a[i]
            a[i + 1] = a[i + 2] * a[i + 1]
            a[i + 2] = a[i + 3] * a[i + 2]
            a[i + 3] = a[i + 4] * a[i + 3]
            a[i + 4] = a[i + 5] * a[i + 4]
            i += 5
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(n)
