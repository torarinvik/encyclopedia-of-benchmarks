from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s126_matrix_column_recurrence")
fn tsvc_s126_matrix_column_recurrence(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 13 or length > 109: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 6: return -1
    let n = Int(n0); let cells = n * n
    if length != c_size_t(1 + 3 * cells): return -1
    for i in range(1, 1 + 3 * cells):
        if input[i] < -100 or input[i] > 100: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var b = List[Int64](length=cells, fill=0)
    for i in range(cells): b[i] = input[1 + 2 * cells + i]
    var k = 1
    for col in range(n):
        for row in range(1, n):
            let target = row * n + col
            b[target] = b[target - n] + input[k] * input[1 + cells + target]
            k += 1
        k += 1
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((b[i] >> (8 * byte)) & 255)
    return Int64(cells)
