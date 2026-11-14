from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("misc_lowercase")
fn misc_lowercase(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 1 or input_length > 32:
        return -1
    let count = input[0]
    if count < 0 or count > 31 or input_length != c_size_t(count + 1):
        return -1

    var units = InlineArray[Int64, 31](fill=0)
    var ascii: UInt8 = 1
    for i in range(Int(count)):
        var unit = input[i + 1]
        if unit < 0 or unit > 65535:
            return -1
        if unit > 127:
            ascii = 0
        if unit >= 65 and unit <= 90:
            unit += 32
        units[i] = unit

    let size = 1 + 2 * Int(count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(size):
        return -2
    output[0] = ascii
    for i in range(Int(count)):
        output[1 + 2 * i] = UInt8(units[i] & 255)
        output[2 + 2 * i] = UInt8((units[i] >> 8) & 255)
    return Int64(size)
