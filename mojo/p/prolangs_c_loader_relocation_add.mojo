# Copyright (c) William Landi 1991. See package LICENSE.txt for permission.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("prolangs_c_loader_relocation_add")
fn prolangs_c_loader_relocation_add(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 5: return -1
    let half_bytes = input[0]
    let delta = input[1]
    if half_bytes < 1 or half_bytes > 6 or delta < -65535 or delta > 65535: return -1
    let width = Int((half_bytes + 1) // 2)
    if length != c_size_t(2 + width): return -1
    var field: Int64 = 0
    for i in range(width):
        let byte = input[2 + i]
        if byte < 0 or byte > 255: return -1
        field = field * 256 + byte
    let adjusted = field + delta
    if adjusted < 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(width): return -2
    var bits = UInt64(adjusted)
    var i = width
    while i > 0:
        i -= 1
        output[i] = UInt8(bits & 255)
        bits >>= 8
    return Int64(width)
