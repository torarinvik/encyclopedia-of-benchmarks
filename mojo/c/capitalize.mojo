from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("capitalize")
fn capitalize(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 256 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if input[i] < 0 or input[i] > 127: return -1
    if capacity < length or (length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var staged = InlineArray[UInt8, 256](0)
    for i in range(length): staged[i] = UInt8(input[i])
    if length > 0 and staged[0] >= 97 and staged[0] <= 122: staged[0] -= 32
    for i in range(length): output[i] = staged[i]
    return Int64(length)
