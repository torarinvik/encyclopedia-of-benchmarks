from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s291_cyclic_neighbor_average")
fn tsvc_s291_cyclic_neighbor_average(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 65: return -1
    let n0 = input[0]
    if n0 < 2 or n0 > 64 or length != c_size_t(n0 + 1): return -1
    let n = Int(n0)
    for i in range(n):
        if input[i + 1] < -1_000_000 or input[i + 1] > 1_000_000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    for i in range(n):
        var previous = i - 1
        if i == 0: previous = n - 1
        let value = input[i + 1] + input[previous + 1]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return n0
