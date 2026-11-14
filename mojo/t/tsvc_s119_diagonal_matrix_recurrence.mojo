from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s119_diagonal_matrix_recurrence")
fn tsvc_s119_diagonal_matrix_recurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > 130: return -1
    let side0 = input[0]
    let passes = input[1]
    if side0 < 2 or side0 > 8 or passes < 1 or passes > 4: return -1
    let side = Int(side0)
    let cells = side * side
    if length != c_size_t(2 + 2 * cells): return -1
    for i in range(2, 2 + 2 * cells):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var a = List[Int64](length=cells, fill=0)
    for i in range(cells):
        a[i] = input[2 + i]
    for _ in range(Int(passes)):
        for row in range(1, side):
            for col in range(1, side):
                let index = row * side + col
                a[index] = a[index - side - 1] + input[2 + cells + index]
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(cells)
