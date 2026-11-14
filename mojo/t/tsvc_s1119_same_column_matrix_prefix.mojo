from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s1119_same_column_matrix_prefix")
fn tsvc_s1119_same_column_matrix_prefix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > 130: return -1
    let n0 = input[0]
    let passes = input[1]
    if n0 < 2 or n0 > 8 or passes < 1 or passes > 4: return -1
    let n = Int(n0)
    let cells = n * n
    if length != c_size_t(2 + 2 * cells): return -1
    for i in range(2, 2 + 2 * cells):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var a = List[Int64](length=cells, fill=0)
    for i in range(cells):
        a[i] = input[2 + i]
    for _ in range(Int(passes)):
        for row in range(1, n):
            for col in range(n):
                let index = row * n + col
                a[index] = a[index - n] + input[2 + cells + index]
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(cells)
