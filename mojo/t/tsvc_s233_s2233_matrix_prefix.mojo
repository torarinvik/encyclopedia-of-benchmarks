from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s233_s2233_matrix_prefix")
fn tsvc_s233_s2233_matrix_prefix(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 14 or length > 194: return -1
    let n0 = input[0]
    let mode = input[1]
    if n0 < 2 or n0 > 8 or mode < 0 or mode > 1: return -1
    let n = Int(n0)
    let cells = n * n
    if length != c_size_t(2 + 3 * cells): return -1
    for i in range(2, 2 + 3 * cells):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * cells): return -2
    var a = List[Int64](length=cells, fill=0)
    var b = List[Int64](length=cells, fill=0)
    for i in range(cells):
        a[i] = input[2 + i]
        b[i] = input[2 + cells + i]
    for col in range(1, n):
        for row in range(1, n):
            let index = row * n + col
            a[index] = a[index - n] + input[2 + 2 * cells + index]
    if mode == 0:
        for col in range(1, n):
            for row in range(1, n):
                let index = row * n + col
                b[index] = b[index - 1] + input[2 + 2 * cells + index]
    else:
        for row in range(1, n):
            for col in range(1, n):
                let index = row * n + col
                b[index] = b[index - n] + input[2 + 2 * cells + index]
    for i in range(cells):
        for byte in range(8):
            output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
            output[8 * (cells + i) + byte] = UInt8((b[i] >> (8 * byte)) & 255)
    return Int64(2 * cells)
