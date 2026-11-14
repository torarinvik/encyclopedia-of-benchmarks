from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s276_index_split_axpy")
fn tsvc_s276_index_split_axpy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 258: return -1
    let n0 = input[0]; let passes = input[1]
    if n0 < 1 or n0 > 64 or passes < 1 or passes > 8 or length != c_size_t(2 + 4 * n0): return -1
    let n = Int(n0)
    for i in range(2, 2 + 4 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    for i in range(n): a[i] = input[2 + i]
    for _ in range(Int(passes)):
        for i in range(n):
            var coefficient = input[2 + 3 * n + i]
            if i + 1 < n // 2: coefficient = input[2 + 2 * n + i]
            a[i] += input[2 + n + i] * coefficient
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return n0
