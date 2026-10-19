from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("brute_force_caesar_cipher")
fn brute_force_caesar_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 64 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(length)):
        if input[i] < 0 or input[i] > 127: return -1
    let required = Int(length) * 26 + 25
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var pos = 0
    for key in range(26):
        for i in range(Int(length)):
            let ch = input[i]
            let mapped = 65 + (ch - 65 + 26 - key) % 26 if ch >= 65 and ch <= 90 else ch
            output[pos] = UInt8(mapped); pos += 1
        if key < 25: output[pos] = 10; pos += 1
    return 26
