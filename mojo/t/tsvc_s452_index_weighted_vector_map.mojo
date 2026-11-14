from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s452_index_weighted_vector_map")
fn tsvc_s452_index_weighted_vector_map(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 129: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + 2 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 2 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    for i in range(n):
        let value = input[1 + i] + input[1 + n + i] * Int64(i + 1)
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return n0
