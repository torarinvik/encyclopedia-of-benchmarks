from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s2102_identity_matrix_initialize")
fn tsvc_s2102_identity_matrix_initialize(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let side0 = input[0]
    let passes = input[1]
    if side0 < 1 or side0 > 8 or passes < 1 or passes > 8: return -1
    let side = Int(side0)
    let cells = side * side
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var matrix = List[Int64](length=cells, fill=0)
    for _ in range(Int(passes)):
        for col in range(side):
            for row in range(side):
                matrix[row * side + col] = 0
            matrix[col * side + col] = 1
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((matrix[i] >> (8 * byte)) & 255)
    return Int64(cells)
