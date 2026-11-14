from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("beebs_bit_compress")
fn beebs_bit_compress(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let data_value = input[0]
    let mask_value = input[1]
    if data_value < 0 or data_value > 4294967295 or mask_value < 0 or mask_value > 4294967295: return -1
    var data = UInt64(data_value)
    var mask = UInt64(mask_value)
    var packed = UInt64(0)
    var destination = UInt64(1)
    while mask != UInt64(0):
        if mask & UInt64(1) != UInt64(0):
            if data & UInt64(1) != UInt64(0): packed |= destination
            destination = destination << 1
        data = data >> 1
        mask = mask >> 1
    return Int64(packed)
