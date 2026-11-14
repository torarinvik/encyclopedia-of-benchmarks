from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("shootout_hello")
fn shootout_hello(calls: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if calls != 1: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 13: return -2
    output[0] = 104
    output[1] = 101
    output[2] = 108
    output[3] = 108
    output[4] = 111
    output[5] = 32
    output[6] = 119
    output[7] = 111
    output[8] = 114
    output[9] = 108
    output[10] = 100
    output[11] = 10
    output[12] = 10
    return 13
