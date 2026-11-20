from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_INPUT_WORDS = 3
const MAX_TRANSITIONS = 16

fn small_power(base: Int64, exponent: Int64) -> Int64:
    var result = Int64(1)
    for _ in range(Int(exponent)):
        result *= base
    return result

fn rebase_hereditary(value: Int64, base: Int64, raised_base: Int64) -> Int64:
    if value == 0:
        return 0
    var result = Int64(0)
    var place = Int64(1)
    var exponent = Int64(0)
    while place <= value:
        let digit = (value // place) % base
        if digit != 0:
            let raised_exponent = rebase_hereditary(exponent, base, raised_base)
            result += digit * small_power(raised_base, raised_exponent)
        place *= base
        exponent += 1
    return result

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8(bits & 255)
        bits = bits >> 8

@export("goodstein_sequence_bounded_prefix")
fn goodstein_sequence_bounded_prefix(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT_WORDS or length != 2:
        return -1
    let start = input[0]
    let transitions = input[1]
    if start < 0 or start > 4 or transitions < 0 or transitions > MAX_TRANSITIONS:
        return -1

    var terms = InlineArray[Int64, 17](fill=0)
    var count = 1
    terms[0] = start
    var current = start
    var base = Int64(2)
    for _ in range(Int(transitions)):
        if current == 0:
            break
        current = rebase_hereditary(current, base, base + 1) - 1
        base += 1
        terms[count] = current
        count += 1

    let output_bytes = (count + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < output_bytes:
        return -2
    store_i64_le(output, 0, Int64(count))
    for index in range(count):
        store_i64_le(output, (index + 1) * 8, terms[index])
    return Int64(output_bytes)
