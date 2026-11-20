# Uncompiled indexed Calkin–Wilf fraction draft.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("calkin_wilf_index")
fn calkin_wilf_index(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let raw = input[0]
    if raw < 1 or raw >= (Int64(1) << 62): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    let index = UInt64(raw)
    var high = UInt64(1)
    while high <= index // 2: high *= 2
    var numerator = UInt64(1)
    var denominator = UInt64(1)
    high //= 2
    while high != 0:
        if (index & high) != 0: numerator += denominator
        else: denominator += numerator
        high //= 2
    for i in range(8):
        output[i] = UInt8((numerator >> (8*i)) & 255)
        output[i+8] = UInt8((denominator >> (8*i)) & 255)
    return 16
