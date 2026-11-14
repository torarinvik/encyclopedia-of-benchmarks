from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s279_nested_branch_recompute")
fn tsvc_s279_nested_branch_recompute(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 322: return -1
    let n0 = input[0]; let passes = input[1]
    if n0 < 1 or n0 > 64 or passes < 1 or passes > 8 or length != c_size_t(2 + 5 * n0): return -1
    let n = Int(n0)
    for i in range(2, 2 + 5 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(24 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var b = List[Int64](length=n, fill=0)
    var c = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[2 + i]; b[i] = input[2 + n + i]; c[i] = input[2 + 2 * n + i]
    for _ in range(Int(passes)):
        for i in range(n):
            let d = input[2 + 3 * n + i]; let e = input[2 + 4 * n + i]
            if a[i] > 0: c[i] = -c[i] + e * e
            else:
                b[i] = -b[i] + d * d
                if b[i] > a[i]: c[i] += d * e
            a[i] = b[i] + c[i] * d
    for i in range(n):
        for byte in range(8):
            output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
            output[8 * (n + i) + byte] = UInt8((b[i] >> (8 * byte)) & 255)
            output[8 * (2 * n + i) + byte] = UInt8((c[i] >> (8 * byte)) & 255)
    return Int64(3 * n)
