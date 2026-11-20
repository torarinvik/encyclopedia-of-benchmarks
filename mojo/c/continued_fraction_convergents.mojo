from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_INPUT_LENGTH = 18

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("continued_fraction_convergents")
fn continued_fraction_convergents(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let count_value = input[0]
    if count_value < 1 or count_value > 16 or input[1] < -1000 or input[1] > 1000:
        return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1): return -1
    for index in range(2, Int(length)):
        if input[index] < 1 or input[index] > 8: return -1
    let required = 16 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var p_two_back: Int64 = 0
    var p_one_back: Int64 = 1
    var q_two_back: Int64 = 1
    var q_one_back: Int64 = 0
    for index in range(count):
        let p = input[index + 1] * p_one_back + p_two_back
        let q = input[index + 1] * q_one_back + q_two_back
        store_i64_le(output, 16 * index, p)
        store_i64_le(output, 16 * index + 8, q)
        p_two_back = p_one_back; p_one_back = p
        q_two_back = q_one_back; q_one_back = q
    return Int64(required)
