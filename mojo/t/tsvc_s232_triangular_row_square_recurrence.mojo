from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s232_triangular_row_square_recurrence")
fn tsvc_s232_triangular_row_square_recurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 51: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 5: return -1
    let n = Int(n0)
    let cells = n * n
    if length != c_size_t(1 + 2 * cells): return -1
    for i in range(1, 1 + 2 * cells):
        if input[i] < -1 or input[i] > 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var a = List[Int64](length=cells, fill=0)
    for i in range(cells):
        a[i] = input[1 + i]
    for row in range(1, n):
        for col in range(1, row + 1):
            let index = row * n + col
            let previous = a[index - 1]
            a[index] = previous * previous + input[1 + cells + index]
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(cells)
