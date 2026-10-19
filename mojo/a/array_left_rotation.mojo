from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn array_left_write(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64):
    let bits = UInt32(value)
    for b in range(4): output[index * 4 + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("array_left_rotation")
fn array_left_rotation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1025: return -1
    let shift = input[0]
    if shift < 0 or shift > 1024: return -1
    let count = Int(length) - 1
    for i in range(count):
        if input[i + 1] < -2147483648 or input[i + 1] > 2147483647: return -1
    if shift >= count: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count * 4): return -2
    for i in range(Int(shift), count): array_left_write(output, i - Int(shift), input[i + 1])
    for i in range(Int(shift)): array_left_write(output, count - Int(shift) + i, input[i + 1])
    return Int64(count)
