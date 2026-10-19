from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List

@export("twos_complement")
fn twos_complement(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if value > 0: return -1
    var bytes = List[UInt8](capacity=67)
    bytes.append(UInt8(48)); bytes.append(UInt8(98))
    if value == 0:
        bytes.append(UInt8(48))
    else:
        let magnitude = UInt64(-(value + 1)) + UInt64(1)
        var bit_length = 0
        var temp = magnitude
        while temp > 0: bit_length += 1; temp = temp >> 1
        let suffix = magnitude if bit_length == 64 else (UInt64(1) << bit_length) - magnitude
        bytes.append(UInt8(49))
        var bits = List[UInt8](capacity=64); var remaining = suffix
        while remaining > 0:
            bits.append(UInt8(48 + (remaining & 1)))
            remaining = remaining >> 1
        for _ in range(len(bits), bit_length): bytes.append(UInt8(48))
        for i in range(len(bits)): bytes.append(bits[len(bits) - 1 - i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(bytes)): return -2
    for i in range(len(bytes)): output[i] = bytes[i]
    return Int64(len(bytes))
