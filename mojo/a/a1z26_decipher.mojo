from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("a1z26_decipher")
fn a1z26_decipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 66 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(length):
        if input[i] < 1 or input[i] > 26:
            return -1
    if capacity < length or (length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    for i in range(length):
        output[i] = UInt8(96 + input[i])
    return Int64(length)
