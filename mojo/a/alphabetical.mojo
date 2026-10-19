from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("alphabetical")
fn alphabetical(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 256 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(Int(length)):
        if values[i] < 0 or values[i] > 127:
            return -1
    if length == 0:
        return 0
    var previous: Int64 = -1
    for i in range(Int(length)):
        let value = values[i]
        if not ((value >= 65 and value <= 90) or (value >= 97 and value <= 122)):
            return 0
        var current = value
        if current >= 65 and current <= 90:
            current += 32
        if current < previous:
            return 0
        previous = current
    return 1
