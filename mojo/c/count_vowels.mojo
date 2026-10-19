from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_vowels")
fn count_vowels(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 4096: return -2
    if length == 1 and values[0] == 48: return -2
    var count: Int64 = 0
    for i in range(length):
        let c = values[i]
        if c < 0 or c > 127 or c == 44: return -2
        if c == 97 or c == 101 or c == 105 or c == 111 or c == 117 or c == 65 or c == 69 or c == 73 or c == 79 or c == 85: count += 1
    return count
