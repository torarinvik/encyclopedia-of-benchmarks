from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("three_dimensional_moment_curve")
fn three_dimensional_moment_curve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let n0 = input[0]
    if n0 < 0 or n0 > 64: return -1
    let n = Int(n0)
    let words = 1 + 3 * n
    let bytes = 8 * words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for word in range(words):
        var value = n0
        if word > 0:
            let x = Int64((word - 1) // 3 + 1)
            let coordinate = (word - 1) % 3
            value = x
            if coordinate >= 1: value *= x
            if coordinate == 2: value *= x
        for byte in range(8): output[8 * word + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
