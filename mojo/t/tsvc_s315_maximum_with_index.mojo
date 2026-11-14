from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s315_maximum_with_index")
fn tsvc_s315_maximum_with_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 64 or length != c_size_t(1 + n0): return -1
    let n = Int(n0)
    for i in range(1, 1 + n):
        if input[i] < -1000000 or input[i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var maximum = input[1]
    var index: Int64 = 0
    for i in range(1, n):
        if input[1 + i] > maximum:
            maximum = input[1 + i]
            index = Int64(i)
    for byte in range(8):
        output[byte] = UInt8((maximum >> (8 * byte)) & 255)
        output[8 + byte] = UInt8((index >> (8 * byte)) & 255)
    return 2
