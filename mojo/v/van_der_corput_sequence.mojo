from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer


@export("van_der_corput_sequence")
fn van_der_corput_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let base = input[0]
    let first_index = input[1]
    let count = input[2]
    if base < 2 or base > 16 or first_index < 1 or first_index > 4096:
        return -1
    if count < 0 or count > 128:
        return -1
    if count > 0 and first_index + count - 1 > 4096:
        return -1

    let output_bytes = Int(count) * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for offset in range(Int(count)):
        var index = first_index + Int64(offset)
        var numerator: UInt64 = 0
        var denominator: UInt64 = 1
        while index > 0:
            numerator = numerator * UInt64(base) + UInt64(index % base)
            denominator = denominator * UInt64(base)
            index = index // base
        let position = offset * 16
        for byte in range(8):
            output[position + byte] = UInt8((numerator >> (byte * 8)) & 255)
            output[position + 8 + byte] = UInt8((denominator >> (byte * 8)) & 255)
    return Int64(output_bytes)
