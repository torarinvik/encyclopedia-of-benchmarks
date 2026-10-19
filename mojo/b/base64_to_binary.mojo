from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn edge_space(value: Int64) -> Bool:
    return (value >= 9 and value <= 13) or value == 32

fn base64_digit(value: Int64) -> Int64:
    if value >= 65 and value <= 90: return value - 65
    if value >= 97 and value <= 122: return value - 71
    if value >= 48 and value <= 57: return value + 4
    if value == 43: return 62
    if value == 47: return 63
    return -1

@export("base64_to_binary")
fn base64_to_binary(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1: return -1
    let n_value = input[0]
    if n_value < 0 or n_value > 256 or length != c_size_t(n_value + 1): return -1
    let n = Int(n_value)
    for i in range(n):
        if input[i + 1] < 0 or input[i + 1] > 127: return -1
    var begin = 0
    var end = n
    while begin < end and edge_space(input[begin + 1]): begin += 1
    while end > begin and edge_space(input[end]): end -= 1
    if begin == end: return -1
    let negative = input[begin + 1] == 45
    if negative: begin += 1
    for i in range(begin, end):
        if base64_digit(input[i + 1]) < 0: return -1
    let required = 6 * (end - begin) + (1 if negative else 0)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var position = 0
    if negative:
        output[position] = UInt8(45)
        position += 1
    for i in range(begin, end):
        let value = UInt8(base64_digit(input[i + 1]))
        for bit in range(5, -1, -1):
            output[position] = UInt8(48) + ((value >> bit) & 1)
            position += 1
    return Int64(required)
