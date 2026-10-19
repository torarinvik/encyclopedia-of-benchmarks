from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime SCALE: UInt64 = 1_000_000

fn digit_count(value_arg: UInt64) -> Int64:
    var value = value_arg
    var count: Int64 = 1
    while value >= 10:
        value /= 10
        count += 1
    return count

fn interval_position(index: Int64, level: Int64) -> UInt64:
    var value: UInt64 = 0
    for bit_index in range(level):
        let shift = level - 1 - bit_index
        let bit = (index >> shift) & 1
        value *= 3
        if bit != 0: value += 2
    return value

fn put_byte(output: UnsafePointer[UInt8, MutAnyOrigin], at: Int64, byte: UInt8) -> Int64:
    output[at] = byte
    return at + 1

fn put_text(output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, text: String) -> Int64:
    var at = at_arg
    for byte in text.as_bytes():
        at = put_byte(output, at, byte)
    return at

fn put_uint(output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, value_arg: UInt64) -> Int64:
    var value = value_arg
    var digits = InlineArray[UInt8, 20](0)
    var count: Int64 = 0
    while True:
        digits[count] = UInt8(48 + value % 10)
        count += 1
        value /= 10
        if value == 0: break
    var at = at_arg
    while count > 0:
        count -= 1
        at = put_byte(output, at, digits[count])
    return at

fn put_fixed(output: UnsafePointer[UInt8, MutAnyOrigin], at_arg: Int64, ticks: UInt64) -> Int64:
    var at = put_uint(output, at_arg, ticks // SCALE)
    at = put_byte(output, at, 46)
    let fraction = ticks % SCALE
    var divisor: UInt64 = 100_000
    while divisor > 0:
        at = put_byte(output, at, UInt8(48 + (fraction // divisor) % 10))
        divisor /= 10
    return at

@export("cantor_set")
fn cantor_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3 or input[0] < 0 or input[0] > input[1] or input[1] > 100000 or input[2] < 0 or input[2] > 6: return -1
    let start = UInt64(input[0])
    let span = UInt64(input[1] - input[0])
    let levels = input[2]
    var denominator: UInt64 = 1
    var required: Int64 = 1
    for level in range(levels + 1):
        required += 7 + digit_count(UInt64(level))
        let count = Int64(1) << level
        for index in range(count):
            let position = interval_position(index, level)
            let left_num = start * denominator + span * position
            let right_num = start * denominator + span * (position + 1)
            let left = (left_num * SCALE + denominator // 2) // denominator
            let right = (right_num * SCALE + denominator // 2) // denominator
            required += 9 + digit_count(left // SCALE) + 7 + digit_count(right // SCALE) + 7
        required += 1
        if level < levels: required += 1
        denominator *= 3
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    denominator = 1
    var at: Int64 = 0
    for level in range(levels + 1):
        at = put_text(output, at, "Level ")
        at = put_uint(output, at, UInt64(level))
        at = put_byte(output, at, 9)
        let count = Int64(1) << level
        for index in range(count):
            let position = interval_position(index, level)
            let left_num = start * denominator + span * position
            let right_num = start * denominator + span * (position + 1)
            let left = (left_num * SCALE + denominator // 2) // denominator
            let right = (right_num * SCALE + denominator // 2) // denominator
            at = put_text(output, at, "\t[")
            at = put_fixed(output, at, left)
            at = put_text(output, at, "] -- [")
            at = put_fixed(output, at, right)
            at = put_byte(output, at, 93)
        at = put_byte(output, at, 10)
        if level < levels: at = put_byte(output, at, 10)
        denominator *= 3
    at = put_byte(output, at, 0)
    return at
