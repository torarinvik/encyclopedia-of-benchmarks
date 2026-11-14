from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s318_strided_absolute_maximum_with_index")
fn tsvc_s318_strided_absolute_maximum_with_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 255: return -1
    let n0 = input[0]
    let stride0 = input[1]
    if n0 < 1 or n0 > 64 or stride0 < 1 or stride0 > 4: return -1
    let n = Int(n0)
    let stride = Int(stride0)
    let physical = 1 + (n - 1) * stride
    if length != c_size_t(2 + physical): return -1
    for i in range(2, 2 + physical):
        if input[i] < -1000000 or input[i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var maximum = input[2]
    if maximum < 0: maximum = -maximum
    var index: Int64 = 0
    for i in range(1, n):
        var magnitude = input[2 + i * stride]
        if magnitude < 0: magnitude = -magnitude
        if magnitude > maximum:
            maximum = magnitude
            index = Int64(i)
    for byte in range(8):
        output[byte] = UInt8((maximum >> (8 * byte)) & 255)
        output[8 + byte] = UInt8((index >> (8 * byte)) & 255)
    return 2
