from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s244_false_dependence_cycle_break")
fn tsvc_s244_false_dependence_cycle_break(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 129: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 32 or length != c_size_t(1 + 4 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 4 * n):
        if input[i] < -2 or input[i] > 2: return -1
    let count = 3 * n - 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * count): return -2
    var a = List[Int64](length=n, fill=0)
    var b = List[Int64](length=n, fill=0)
    var trace = List[Int64](length=n - 1, fill=0)
    for i in range(n):
        a[i] = input[1 + i]
        b[i] = input[1 + n + i]
    for i in range(n - 1):
        let c = input[1 + 2 * n + i]
        let d = input[1 + 3 * n + i]
        a[i] = b[i] + c * d
        b[i] = c + b[i]
        a[i + 1] = b[i] + a[i + 1] * d
        trace[i] = a[i + 1]
    for i in range(count):
        var value: Int64 = 0
        if i < n:
            value = a[i]
        elif i < 2 * n:
            value = b[i - n]
        else:
            value = trace[i - 2 * n]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(count)
