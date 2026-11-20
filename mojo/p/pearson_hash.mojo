from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("pearson_hash")
fn pearson_hash(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 257 or length > 322:
        return -1
    let declared = input[0]
    if declared < 0 or declared > 64 or length != c_size_t(257 + declared):
        return -1

    var table = InlineArray[UInt8, 256]()
    var used = InlineArray[Bool, 256](fill=False)
    for slot in range(256):
        let value = input[1 + slot]
        if value < 0 or value > 255:
            return -1
        let byte = Int(value)
        if used[byte]:
            return -1
        used[byte] = True
        table[slot] = UInt8(byte)

    for offset in range(Int(declared)):
        let value = input[257 + offset]
        if value < 0 or value > 255:
            return -1
    var state: UInt8 = 0
    for offset in range(Int(declared)):
        let byte = UInt8(input[257 + offset])
        state = table[Int(state ^ byte)]
    return Int64(state)
