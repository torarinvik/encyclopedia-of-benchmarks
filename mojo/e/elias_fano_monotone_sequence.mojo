from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VALUES = 32
comptime MAX_HIGH_BITS = 96
comptime MAX_INPUT_LENGTH = 35

@export("elias_fano_monotone_sequence")
fn elias_fano_monotone_sequence(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let count_value = input[0]
    let upper = input[1]
    if count_value < 1 or count_value > MAX_VALUES or upper < 0 or upper > 1_000_000:
        return -1
    let count = Int(count_value)
    if count_value > upper + 1 or length != c_size_t(count + 2):
        return -1

    var source = InlineArray[Int64, MAX_VALUES](fill=0)
    for index in range(count):
        let value = input[index + 2]
        if value < 0 or value > upper:
            return -1
        if index > 0 and value < source[index - 1]:
            return -1
        source[index] = value

    var low_width = 0
    var low_power: Int64 = 1
    while count_value * low_power * 2 <= upper + 1:
        low_power *= 2
        low_width += 1
    let low_mask = low_power - 1
    var low_parts = InlineArray[Int64, MAX_VALUES](fill=0)
    var high_bits = InlineArray[Bool, MAX_HIGH_BITS](fill=False)
    let high_length = Int(upper / low_power) + count
    if high_length > MAX_HIGH_BITS:
        return -1
    for index in range(count):
        low_parts[index] = source[index] & low_mask
        let position = Int(source[index] / low_power) + index
        if position < 0 or position >= high_length:
            return -1
        high_bits[position] = True

    var checksum: Int64 = 0
    var item_index = 0
    for position in range(high_length):
        if high_bits[position]:
            if item_index >= count or position < item_index:
                return -1
            let high_part = position - item_index
            let decoded = (Int64(high_part) << low_width) | low_parts[item_index]
            checksum += Int64(item_index + 1) * decoded
            item_index += 1
    if item_index != count:
        return -1
    return checksum
