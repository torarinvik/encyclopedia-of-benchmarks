from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s252_adjacent_product_pair_sum")
fn tsvc_s252_adjacent_product_pair_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 129: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + 2 * n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + 2 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var previous: Int64 = 0
    for i in range(n):
        let product = input[1 + i] * input[1 + n + i]
        a[i] = product + previous
        previous = product
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(n)
