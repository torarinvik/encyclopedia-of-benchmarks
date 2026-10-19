from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("atbash_cipher")
fn atbash_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 66 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(Int(length)):
        if input[i] < 0 or input[i] > 127:
            return -1
    if capacity < length or (length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    for i in range(Int(length)):
        let value = input[i]
        var mapped = value
        if value >= 65 and value <= 90:
            mapped = 155 - value
        elif value >= 97 and value <= 122:
            mapped = 219 - value
        output[i] = UInt8(mapped)
    return Int64(length)
