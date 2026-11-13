from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn cdc_reduce(mut value: UInt32) -> UInt16:
    for step in range(16):
        let bit = 31 - step
        if value & (UInt32(1) << UInt(bit)) != 0: value ^= UInt32(0x1100b) << UInt(bit - 16)
    return UInt16(value)

@export("rabin_content_defined_chunking")
fn rabin_content_defined_chunking(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    if input[0] < 0 or input[0] > 64: return -1
    let n = Int(input[0])
    if length != c_size_t(n + 1): return -1
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > 255: return -1
    var outgoing = InlineArray[UInt16, 256](fill=0)
    for i in range(256): outgoing[i] = cdc_reduce(UInt32(i) << 24)
    var fingerprint = UInt16(0)
    var boundaries = InlineArray[UInt8, 64](fill=0)
    var count = 0
    for i in range(n):
        fingerprint = cdc_reduce((UInt32(fingerprint) << 8) | UInt32(input[i + 1]))
        if i >= 4: fingerprint ^= outgoing[Int(input[i - 3])]
        if fingerprint & 7 == 0:
            boundaries[count] = UInt8(i + 1)
            count += 1
    if n > 0:
        var append_final = count == 0
        if count > 0: append_final = Int(boundaries[count - 1]) != n
        if append_final:
            boundaries[count] = UInt8(n)
            count += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2
    for i in range(count): output[i] = boundaries[i]
    return Int64(count)
