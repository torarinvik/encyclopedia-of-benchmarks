from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_to_gray")
fn binary_to_gray(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    for i in range(Int(length)):
        if input[i] != 48 and input[i] != 49: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < length: return -2
    var bytes = List[UInt8](capacity=Int(length)); bytes.append(UInt8(input[0]))
    for i in range(1, Int(length)): bytes.append(UInt8(48 + ((input[i - 1] - 48) ^ (input[i] - 48))))
    for i in range(Int(length)): output[i] = bytes[i]
    return Int64(length)
