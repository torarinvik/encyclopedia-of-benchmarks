from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s171_stride_indexed_accumulate")
fn tsvc_s171_stride_indexed_accumulate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 159: return -1
    let n0 = input[0]
    let stride0 = input[1]
    if n0 < 1 or n0 > 32 or stride0 < 1 or stride0 > 4: return -1
    let n = Int(n0)
    let stride = Int(stride0)
    let a_length = 1 + (n - 1) * stride
    if length != c_size_t(2 + a_length + n): return -1
    for i in range(2, 2 + a_length + n):
        if input[i] < -8 or input[i] > 8: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * a_length): return -2
    var a = List[Int64](length=a_length, fill=0)
    for i in range(a_length):
        a[i] = input[2 + i]
    for i in range(n):
        a[i * stride] += input[2 + a_length + i]
    for i in range(a_length):
        for byte in range(8): output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
    return Int64(a_length)
