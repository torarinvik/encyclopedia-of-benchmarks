from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("first_unique_character")
fn first_unique_character(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 1024 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -2
    var counts = InlineArray[Int32, 26](fill=0)
    for i in range(Int(length)):
        let v = input[i]
        if v < 97 or v > 122: return -2
        counts[Int(v - 97)] += 1
    for i in range(Int(length)):
        if counts[Int(input[i] - 97)] == 1: return Int64(i)
    return -1
