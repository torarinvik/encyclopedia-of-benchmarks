from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn residue(value: Int64, modulus: Int64) -> Int64:
    var result = value % modulus
    if result < 0:
        result += modulus
    return result

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
              value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("mrg32k3a_combined_recursive_generator")
fn mrg32k3a_combined_recursive_generator(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 7:
        return -1
    var x1 = InlineArray[Int64, 3]()
    var x2 = InlineArray[Int64, 3]()
    for index in range(3):
        x1[index] = input[index]
        x2[index] = input[index + 3]
    for index in range(3):
        if x1[index] < 0 or x1[index] >= 4294967087:
            return -1
        if x2[index] < 0 or x2[index] >= 4294944443:
            return -1
    if (x1[0] | x1[1] | x1[2]) == 0 or (x2[0] | x2[1] | x2[2]) == 0:
        return -1
    let count_value = input[6]
    if count_value < 0 or count_value > 64:
        return -1
    let count = Int(count_value)
    let required = count * 8
    if count == 0:
        return 0
    if capacity < c_size_t(required) or output == UnsafePointer[UInt8, MutAnyOrigin]():
        return -2

    for step in range(count):
        let next1 = residue(1403580 * x1[1] - 810728 * x1[0], 4294967087)
        let next2 = residue(527612 * x2[2] - 1370589 * x2[0], 4294944443)
        x1[0] = x1[1]
        x1[1] = x1[2]
        x1[2] = next1
        x2[0] = x2[1]
        x2[1] = x2[2]
        x2[2] = next2
        var z = next1 - next2
        if z < 0:
            z += 4294967087
        put_i64_le(output, step * 8, z)
    return Int64(required)
