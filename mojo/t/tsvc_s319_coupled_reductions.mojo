from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s319_coupled_reductions")
fn tsvc_s319_coupled_reductions(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 193: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + 3 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 3 * n):
        if input[i] < -2 or input[i] > 2: return -1
    let count = 2 * n + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * count): return -2
    var values = List[Int64](length=count, fill=0)
    var total: Int64 = 0
    for i in range(n):
        let c = input[1 + i]
        values[i] = c + input[1 + n + i]
        total += values[i]
        values[n + i] = c + input[1 + 2 * n + i]
        total += values[n + i]
    values[2 * n] = total
    for i in range(count):
        for byte in range(8): output[8 * i + byte] = UInt8((values[i] >> (8 * byte)) & 255)
    return Int64(count)
