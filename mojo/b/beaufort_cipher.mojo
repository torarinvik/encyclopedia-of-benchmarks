from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("beaufort_cipher")
fn beaufort_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 2051: return -1
    let mode = input[0]
    let text_value = input[1]
    let key_value = input[2]
    if (mode != 0 and mode != 1) or text_value < 0 or text_value > 1024 or key_value < 0 or key_value > 1024: return -1
    let text_length = Int(text_value)
    let key_length = Int(key_value)
    if length != c_size_t(3 + text_length + key_length) or
       (text_length == 0 and key_length != 0) or
       (text_length != 0 and (key_length == 0 or key_length > text_length)): return -1
    let key_start = 3 + text_length
    for i in range(text_length):
        let ch = input[3 + i]
        if ch != 32 and (ch < 65 or ch > 90): return -1
    for i in range(key_length):
        let ch = input[key_start + i]
        if ch < 65 or ch > 90: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(text_length): return -2
    var key_index = 0
    for i in range(text_length):
        let value = input[3 + i]
        if value == 32:
            output[i] = UInt8(32)
            continue
        let letter = value - 65
        let key = input[key_start + key_index % key_length] - 65
        let mapped = (letter - key + 26) % 26 if mode == 0 else (letter + key) % 26
        output[i] = UInt8(65 + mapped)
        key_index += 1
    return Int64(text_length)
