from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("convert_to_negative")
fn convert_to_negative(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 4096: return -1
    let count = values[0]
    if count < 0 or count > 4095 or count != length - 1: return -1
    for i in range(count):
        if values[i + 1] < 0 or values[i + 1] > 255: return -1
    if count > output_capacity or (count != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(count): output[i] = UInt8(255 - values[i + 1])
    return count
