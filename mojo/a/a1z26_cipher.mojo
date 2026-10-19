from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("a1z26_cipher")
fn a1z26_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 66 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(length):
        let v = input[i]
        if not ((v >= 65 and v <= 90) or (v >= 97 and v <= 122)):
            return -1
    if capacity < length or (length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    for i in range(length):
        let v = input[i]
        if v >= 97:
            output[i] = UInt8(v - 96)
        else:
            output[i] = UInt8(v - 64)
    return Int64(length)
