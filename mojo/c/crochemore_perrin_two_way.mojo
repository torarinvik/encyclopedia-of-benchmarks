from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_TEXT_LENGTH = 64
comptime MAX_PATTERN_LENGTH = 32
comptime MAX_INPUT_LENGTH = 99

fn maximal_suffix(
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], length: Int,
    reverse_order: Bool,
) -> InlineArray[Int, 2]:
    var state = InlineArray[Int, 2](fill=0)
    var maximal = -1
    var candidate = 0
    var offset = 1
    var period = 1
    while candidate + offset < length:
        let a = pattern[candidate + offset]
        let b = pattern[maximal + offset]
        let precedes = a > b if reverse_order else a < b
        if precedes:
            candidate += offset
            offset = 1
            period = candidate - maximal
        elif a == b:
            if offset != period: offset += 1
            else:
                candidate += period
                offset = 1
        else:
            maximal = candidate
            candidate = maximal + 1
            offset = 1
            period = 1
    state[0] = maximal
    state[1] = period
    return state

fn two_way(
    text: InlineArray[Int64, MAX_TEXT_LENGTH], text_length: Int,
    pattern: InlineArray[Int64, MAX_PATTERN_LENGTH], pattern_length: Int,
) -> InlineArray[Int64, MAX_TEXT_LENGTH + 2]:
    var result = InlineArray[Int64, MAX_TEXT_LENGTH + 2](fill=0)
    var count = 0
    if pattern_length == 0:
        for i in range(text_length + 1):
            result[count + 1] = Int64(i)
            count += 1
        result[0] = Int64(count)
        return result
    if pattern_length > text_length: return result

    let first = maximal_suffix(pattern, pattern_length, False)
    let second = maximal_suffix(pattern, pattern_length, True)
    let critical = first[0] if first[0] > second[0] else second[0]
    let period = first[1] if first[0] > second[0] else second[1]
    var periodic = period + critical + 1 <= pattern_length
    for i in range(critical + 1):
        if not periodic: break
        if pattern[i] != pattern[i + period]: periodic = False
    let shift = period if periodic else max(critical, pattern_length - critical - 1) + 1
    var memory = -1
    var start = 0
    while start <= text_length - pattern_length:
        var index = critical + 1
        if periodic and memory > critical: index = memory + 1
        while index < pattern_length and pattern[index] == text[start + index]:
            index += 1
        if index >= pattern_length:
            index = critical
            while index > memory and pattern[index] == text[start + index]:
                index -= 1
            if index <= memory:
                result[count + 1] = Int64(start)
                count += 1
            start += shift
            memory = pattern_length - period - 1 if periodic else -1
        else:
            start += index - critical
            memory = -1
    result[0] = Int64(count)
    return result

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("crochemore_perrin_two_way")
fn crochemore_perrin_two_way(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let text_value = input[0]
    let pattern_value = input[1]
    if text_value < 0 or text_value > MAX_TEXT_LENGTH or pattern_value < 0 or pattern_value > MAX_PATTERN_LENGTH:
        return -1
    let text_length = Int(text_value)
    let pattern_length = Int(pattern_value)
    if length != c_size_t(2 + text_length + pattern_length): return -1
    var text = InlineArray[Int64, MAX_TEXT_LENGTH](fill=0)
    var pattern = InlineArray[Int64, MAX_PATTERN_LENGTH](fill=0)
    for i in range(text_length):
        let value = input[2 + i]
        if value < 0 or value > 255: return -1
        text[i] = value
    for i in range(pattern_length):
        let value = input[2 + text_length + i]
        if value < 0 or value > 255: return -1
        pattern[i] = value

    let matches = two_way(text, text_length, pattern, pattern_length)
    let match_count = Int(matches[0])
    let output_bytes = match_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for i in range(match_count): store_i64_le(output, i * 8, matches[i + 1])
    return Int64(output_bytes)
