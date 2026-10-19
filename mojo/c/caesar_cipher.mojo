from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("caesar_cipher")
fn caesar_cipher(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 66: return -1
    let text_length = length - 1
    for i in range(text_length):
        if input[i] < 0 or input[i] > 127: return -1
    if capacity < text_length or (text_length > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    var shift = input[text_length] % 26
    if shift < 0: shift += 26
    var staged = InlineArray[UInt8, 65](0)
    for i in range(text_length):
        let value = input[i]
        var mapped = value
        if value >= 65 and value <= 90: mapped = 65 + (value - 65 + shift) % 26
        elif value >= 97 and value <= 122: mapped = 97 + (value - 97 + shift) % 26
        staged[i] = UInt8(mapped)
    for i in range(text_length): output[i] = staged[i]
    return Int64(text_length)
