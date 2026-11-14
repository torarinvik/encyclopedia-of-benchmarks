from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s235_fused_vector_matrix_recurrence")
fn tsvc_s235_fused_vector_matrix_recurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 15 or length > 153: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 8: return -1
    let n = Int(n0)
    let cells = n * n
    if length != c_size_t(1 + 3 * n + 2 * cells): return -1
    for i in range(1, 1 + 3 * n + 2 * cells):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * (n + cells)): return -2
    var a = List[Int64](length=n, fill=0)
    var aa = List[Int64](length=cells, fill=0)
    for i in range(n): a[i] = input[1 + i]
    for i in range(cells): aa[i] = input[1 + 3 * n + i]
    for col in range(n):
        a[col] += input[1 + n + col] * input[1 + 2 * n + col]
        for row in range(1, n):
            let index = row * n + col
            aa[index] = aa[index - n] + input[1 + 3 * n + cells + index] * a[col]
    for i in range(n + cells):
        var value: Int64 = 0
        if i < n:
            value = a[i]
        else:
            value = aa[i - n]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(n + cells)
