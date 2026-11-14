from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("tsvc_s273_dependent_conditional_update")
fn tsvc_s273_dependent_conditional_update(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 322: return -1
    let n0 = input[0]; let passes = input[1]
    if n0 < 1 or n0 > 64 or passes < 1 or passes > 8 or length != c_size_t(2 + 5 * n0): return -1
    let n = Int(n0)
    for i in range(2, 2 + 5 * n):
        if input[i] < -2 or input[i] > 2: return -1
    var a = List[Int64](length=n, fill=0)
    var b = List[Int64](length=n, fill=0)
    var c = List[Int64](length=n, fill=0)
    for i in range(n):
        a[i] = input[2 + i]; b[i] = input[2 + n + i]; c[i] = input[2 + 2 * n + i]
    for _ in range(Int(passes)):
        for i in range(n):
            let d = input[2 + 3 * n + i]; let e = input[2 + 4 * n + i]
            a[i] += d * e
            if a[i] < 0: b[i] += d * e
            c[i] += a[i] * d
    var total = Int64(0)
    for i in range(n): total += a[i] + b[i] + c[i]
    return total
