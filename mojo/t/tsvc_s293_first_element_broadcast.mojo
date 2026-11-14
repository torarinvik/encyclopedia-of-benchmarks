from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s293_first_element_broadcast")
fn tsvc_s293_first_element_broadcast(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 33: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 32 or length != c_size_t(n0 + 1): return -1
    let n = Int(n0)
    for i in range(n):
        if input[i + 1] < -8 or input[i + 1] > 8: return -1
    let bytes = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = List[Int64](length=n, fill=0)
    for i in range(n): staged[i] = input[1]
    for i in range(n):
        for byte in range(8): output[8 * i + byte] = UInt8((staged[i] >> (8 * byte)) & 255)
    return Int64(bytes)
