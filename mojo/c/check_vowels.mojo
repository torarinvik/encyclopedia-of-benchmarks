from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("check_vowels")
fn check_vowels(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if values[i] < 97 or values[i] > 122: return -1
    for i in range(length):
        let value = values[i]
        if value == 97 or value == 101 or value == 105 or value == 111 or value == 117: return 1
    return 0
