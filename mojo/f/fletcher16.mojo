from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fletcher16")
fn fletcher16(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var s1: UInt32 = 0
    var s2: UInt32 = 0
    for i in range(Int(length)):
        let b = input[i]
        if b < 0 or b > 127: return -1
        s1 = (s1 + UInt32(b)) % 255
        s2 = (s2 + s1) % 255
    return Int64((s2 << 8) | s1)
