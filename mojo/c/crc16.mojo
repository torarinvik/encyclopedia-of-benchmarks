from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("crc16")
fn crc16(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 100001 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var crc: Int64 = 65535
    for i in range(length):
        let byte = values[i]
        if byte < 0 or byte > 255: return -1
        for bit in range(8):
            let incoming = (byte >> (7 - bit)) & 1
            let top = (crc >> 15) & 1
            crc = (crc << 1) & 65535
            if (top ^ incoming) != 0: crc ^= 4129
    return crc
