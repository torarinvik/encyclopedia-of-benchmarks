from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("count_consonants")
fn count_consonants(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length == 0 or length > 4096 or values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    if length == 1 and values[0] == 48: return -1
    var count: Int64 = 0
    for i in range(length):
        var value = values[i]
        if value < 32 or value > 126: return -1
        if value >= 65 and value <= 90: value += 32
        if value >= 97 and value <= 122 and value != 97 and value != 101 and value != 105 and value != 111 and value != 117: count += 1
    return count
