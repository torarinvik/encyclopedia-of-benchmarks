from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s141_packed_symmetric_update")
fn tsvc_s141_packed_symmetric_update(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 394: return -1
    let n0 = input[0]
    let rounds = input[1]
    if n0 < 1 or n0 > 16 or rounds < 1 or rounds > 32: return -1
    let n = Int(n0)
    let triangle = n * (n + 1) // 2
    if length != c_size_t(2 + triangle + n * n): return -1
    for i in range(2, 2 + triangle + n * n):
        if input[i] < -1000000 or input[i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * triangle): return -2
    var packed = List[Int64](length=triangle, fill=0)
    for i in range(triangle):
        packed[i] = input[2 + i]
    for _ in range(Int(rounds)):
        for i in range(n):
            for j in range(i, n):
                let k = j * (j + 1) // 2 + i
                packed[k] += input[2 + triangle + j * n + i]
    for i in range(triangle):
        for byte in range(8): output[8 * i + byte] = UInt8((packed[i] >> (8 * byte)) & 255)
    return Int64(triangle)
