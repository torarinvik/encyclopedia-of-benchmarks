from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("camel_case_to_snake_case")
fn camel_case_to_snake_case(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 256: return -1
    var out_len: Int64 = 0
    for i in range(length):
        let v = input[i]
        if v >= 65 and v <= 90:
            if i > 0: out_len += 1
        elif v < 97 or v > 122: return -1
        out_len += 1
    if capacity < out_len or output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    var staged = InlineArray[UInt8, 512](0)
    var pos: Int64 = 0
    for i in range(length):
        let v = input[i]
        if v >= 65 and v <= 90:
            if i > 0:
                staged[pos] = 95
                pos += 1
            staged[pos] = UInt8(v + 32)
        else:
            staged[pos] = UInt8(v)
        pos += 1
    for i in range(out_len): output[i] = staged[i]
    return out_len
