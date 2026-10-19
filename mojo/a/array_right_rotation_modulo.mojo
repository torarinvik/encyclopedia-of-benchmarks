from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn array_right_mod_write(output: UnsafePointer[UInt8, MutAnyOrigin], index: Int, value: Int64):
    let bits = UInt32(value)
    for b in range(4): output[index * 4 + b] = UInt8((bits >> UInt(8 * b)) & 255)

@export("array_right_rotation_modulo")
fn array_right_rotation_modulo(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1025: return -1
    let rotations = input[0]
    if rotations < 0 or rotations > 2147483647: return -1
    let count = Int(length) - 1
    for i in range(count):
        if input[i + 1] < -2147483648 or input[i + 1] > 2147483647: return -1
    if count == 0: return -1
    let shift = Int(rotations % Int64(count))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count * 4): return -2
    for i in range(shift): array_right_mod_write(output, i, input[count - shift + i + 1])
    for i in range(count - shift): array_right_mod_write(output, shift + i, input[i + 1])
    return Int64(count)
