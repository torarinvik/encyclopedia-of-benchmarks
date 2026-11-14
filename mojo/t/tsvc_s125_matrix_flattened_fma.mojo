from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s125_matrix_flattened_fma")
fn tsvc_s125_matrix_flattened_fma(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 193: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 8: return -1
    let n = Int(n0); let cells = n * n
    if length != c_size_t(1 + 3 * cells): return -1
    for i in range(1, 1 + 3 * cells):
        if input[i] < -100 or input[i] > 100: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * cells): return -2
    var result = List[Int64](length=cells, fill=0)
    var k = 0
    for _ in range(n):
        for _ in range(n):
            result[k] = input[1 + k] + input[1 + cells + k] * input[1 + 2 * cells + k]
            k += 1
    for i in range(cells):
        for byte in range(8): output[8 * i + byte] = UInt8((result[i] >> (8 * byte)) & 255)
    return Int64(cells)
