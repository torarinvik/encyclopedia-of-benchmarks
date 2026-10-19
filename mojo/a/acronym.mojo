from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("acronym")
fn acronym(phrase: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 79 or (length > 0 and phrase == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    var needed = 0
    for i in range(length):
        let c = phrase[i]
        if c < 1 or c > 127:
            return -1
        if c != 32 and (i == 0 or phrase[i - 1] == 32):
            needed += 1
    if capacity < c_size_t(needed) or (needed > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    var out = 0
    for i in range(length):
        let c = phrase[i]
        if c != 32 and (i == 0 or phrase[i - 1] == 32):
            if c >= 97 and c <= 122:
                output[out] = UInt8(c - 32)
            else:
                output[out] = UInt8(c)
            out += 1
    return Int64(out)
