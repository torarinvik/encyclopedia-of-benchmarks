from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("adler32")
fn adler32(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 100001 or (length > 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1
    var a: UInt32 = 1
    var b: UInt32 = 0
    for i in range(length):
        let value = values[i]
        if value < 0 or value > 255:
            return -1
        a = (a + UInt32(value)) % 65521
        b = (b + a) % 65521
    return Int64((b << 16) | a)
