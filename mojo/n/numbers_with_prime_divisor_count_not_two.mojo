from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_INPUT_LENGTH = 2
const MAX_LIMIT = 1000

fn is_prime_count(value: UInt16) -> Bool:
    if value < 2: return False
    var divisor = UInt16(2)
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
             value: Int64) -> None:
    var bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("numbers_with_prime_divisor_count_not_two")
fn numbers_with_prime_divisor_count_not_two(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_LENGTH:
        return -1
    if length != 1: return -1
    let limit_value = input[0]
    if limit_value < 1 or limit_value > MAX_LIMIT: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2

    let limit = Int(limit_value)
    var divisor_counts = InlineArray[UInt16, MAX_LIMIT]()
    for divisor in range(1, limit):
        var multiple = divisor
        while multiple < limit:
            divisor_counts[multiple] += 1
            multiple += divisor

    var selected_count = 0
    for n in range(1, limit):
        let count = divisor_counts[n]
        if count != 2 and is_prime_count(count): selected_count += 1
    let output_bytes = selected_count * 8
    if capacity < c_size_t(output_bytes): return -2

    var output_index = 0
    for n in range(1, limit):
        let count = divisor_counts[n]
        if count != 2 and is_prime_count(count):
            store_i64(output, output_index * 8, Int64(n))
            output_index += 1
    return Int64(output_bytes)
