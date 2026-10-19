from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("crc32")
fn crc32(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 100001 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var crc: Int64 = 4294967295
    for i in range(length):
        let byte = values[i]
        if byte < 0 or byte > 255: return -1
        crc ^= byte
        for bit in range(8):
            crc = ((crc >> 1) ^ 3988292384) if (crc & 1) != 0 else crc >> 1
    return crc ^ 4294967295
