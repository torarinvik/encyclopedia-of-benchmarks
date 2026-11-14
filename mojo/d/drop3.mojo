from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("drop3")
fn drop3(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4097 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    if length > 4096: return -1
    var result: Int64 = 0
    for _ in range(20):
        var index = 0
        var remaining = Int(length) * 8
        var phase = 0
        var buffer: UInt32 = 0
        var kept_bits = 0
        while remaining >= 3:
            remaining -= 3
            let offset = (phase * 5) & 7
            if offset < 3:
                buffer |= UInt32(input[index]) << (8 - offset)
                index += 1
            if ((buffer >> 13) & 7) >= 4: kept_bits += 3
            buffer = (buffer << 3) & 65535
            phase = (phase + 1) & 7
        result = Int64(kept_bits >> 3)
    return result
