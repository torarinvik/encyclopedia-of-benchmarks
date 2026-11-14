from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s332_first_above_threshold")
fn tsvc_s332_first_above_threshold(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 258: return -1
    let n0 = input[0]; let threshold = input[1]
    if n0 < 1 or n0 > 256 or threshold < -1_000_000 or threshold > 1_000_000 or length != c_size_t(n0 + 2): return -1
    let n = Int(n0)
    for i in range(n):
        if input[i + 2] < -1_000_000 or input[i + 2] > 1_000_000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var index = Int64(-2); var value = Int64(-1)
    for i in range(n):
        if input[i + 2] > threshold:
            index = Int64(i); value = input[i + 2]
            break
    for byte in range(8):
        output[byte] = UInt8((index >> (8 * byte)) & 255)
        output[8 + byte] = UInt8((value >> (8 * byte)) & 255)
    return 2
