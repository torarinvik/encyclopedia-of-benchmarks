from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("get_last_item")
fn get_last_item(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 64 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    for i in range(Int(length)):
        if values[i] < 0 or values[i] > 100000: return -1
    if length == 0: return -1
    return values[Int(length) - 1]
