from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_INPUT_WORDS = 2
const MAX_LIMIT = 100

fn is_squarefree(value: Int64) -> Bool:
    var divisor = Int64(2)
    while divisor <= value // divisor:
        if value % (divisor * divisor) == 0:
            return False
        divisor += 1
    return True

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("powerful_numbers_square_cube_enumeration")
fn powerful_numbers_square_cube_enumeration(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_WORDS or length != 1:
        return -1
    let limit = input[0]
    if limit < 1 or limit > MAX_LIMIT:
        return -1

    var values = InlineArray[Int64, 14](fill=0)
    var count = 0
    for b in range(1, Int(limit) + 1):
        let wide_b = Int64(b)
        if wide_b * wide_b * wide_b > limit:
            break
        if not is_squarefree(wide_b):
            continue
        let cube = wide_b * wide_b * wide_b
        var a = Int64(1)
        while a * a * cube <= limit:
            values[count] = a * a * cube
            count += 1
            a += 1

    for index in range(1, count):
        let value = values[index]
        var position = index
        while position > 0 and values[position - 1] > value:
            values[position] = values[position - 1]
            position -= 1
        values[position] = value

    let output_bytes = (count + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < output_bytes:
        return -2
    store_i64_le(output, 0, Int64(count))
    for index in range(count):
        store_i64_le(output, (index + 1) * 8, values[index])
    return Int64(output_bytes)
