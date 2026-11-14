from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1281_elementwise_dual_update")
fn tsvc_s1281_elementwise_dual_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 82: return -1
    let n0 = input[0]; let passes0 = input[1]
    if n0 < 1 or n0 > 16 or passes0 < 1 or passes0 > 8 or length != c_size_t(2 + 5 * n0): return -1
    let n = Int(n0)
    for i in range(2, 2 + 5 * n):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var b = List[Int64](length=n, fill=0)
    for i in range(n): a[i] = input[2 + i]; b[i] = input[2 + n + i]
    for _ in range(Int(passes0)):
        for i in range(n):
            let x = b[i] * input[2 + 2 * n + i] + a[i] * input[2 + 3 * n + i] + input[2 + 4 * n + i]
            a[i] = x - 1; b[i] = x
    for i in range(n):
        for byte in range(8):
            output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
            output[8 * (n + i) + byte] = UInt8((b[i] >> (8 * byte)) & 255)
    return Int64(16 * n)
