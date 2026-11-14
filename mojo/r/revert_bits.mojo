from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn reverse64(value: UInt64) -> UInt64:
    var x = value
    x = ((x >> 1) & UInt64(0x5555555555555555)) | ((x & UInt64(0x5555555555555555)) << 1)
    x = ((x >> 2) & UInt64(0x3333333333333333)) | ((x & UInt64(0x3333333333333333)) << 2)
    x = ((x >> 4) & UInt64(0x0f0f0f0f0f0f0f0f)) | ((x & UInt64(0x0f0f0f0f0f0f0f0f)) << 4)
    x = ((x >> 8) & UInt64(0x00ff00ff00ff00ff)) | ((x & UInt64(0x00ff00ff00ff00ff)) << 8)
    x = ((x >> 16) & UInt64(0x0000ffff0000ffff)) | ((x & UInt64(0x0000ffff0000ffff)) << 16)
    return (x >> 32) | (x << 32)

@export("revert_bits")
fn revert_bits(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let first = input[0]
    let second = input[1]
    if first < 0 or first > 4294967295: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 12: return -2
    let a = reverse64(UInt64(first)) >> 32
    let b = reverse64(bitcast[UInt64](second))
    for i in range(4): output[i] = UInt8((a >> (8 * i)) & 255)
    for i in range(8): output[4 + i] = UInt8((b >> (8 * i)) & 255)
    return 12
