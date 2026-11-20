from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_TEXT = 4096
comptime MAX_PATTERN = 128
comptime MAX_INPUT_LENGTH = 4227
comptime MAX_BUCKETS = 64

@export("alpha_skip_search")
fn alpha_skip_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_text_length = input[0]
    let raw_pattern_length = input[1]
    if raw_text_length < 0 or raw_text_length > MAX_TEXT or
        raw_pattern_length < 1 or raw_pattern_length > MAX_PATTERN:
        return -1
    let text_length = Int(raw_text_length)
    let pattern_length = Int(raw_pattern_length)
    if length != c_size_t(2 + text_length + pattern_length):
        return -1

    var text = InlineArray[UInt8, MAX_TEXT](fill=0)
    var pattern = InlineArray[UInt8, MAX_PATTERN](fill=0)
    for index in range(text_length):
        let symbol = input[2 + index]
        if symbol < 0 or symbol > 3:
            return -1
        text[index] = UInt8(symbol)
    for index in range(pattern_length):
        let symbol = input[2 + text_length + index]
        if symbol < 0 or symbol > 3:
            return -1
        pattern[index] = UInt8(symbol)
    if text_length < pattern_length:
        return 0

    var factor_length = 1
    var bucket_count = 4
    while bucket_count * 4 <= pattern_length:
        factor_length += 1
        bucket_count *= 4
    let shift = pattern_length - factor_length + 1
    var power = 1
    for _ in range(1, factor_length):
        power *= 4

    var heads = InlineArray[Int, MAX_BUCKETS](fill=-1)
    var next_factor = InlineArray[Int, MAX_PATTERN](fill=-1)
    var factor_code = 0
    for index in range(factor_length):
        factor_code = factor_code * 4 + Int(pattern[index])
    for position in range(pattern_length - factor_length + 1):
        next_factor[position] = heads[factor_code]
        heads[factor_code] = position
        if position + factor_length < pattern_length:
            factor_code = (factor_code - Int(pattern[position]) * power) * 4 + Int(pattern[position + factor_length])

    var match_count: Int64 = 0
    var offset_sum: Int64 = 0
    var offset_xor: Int64 = 0
    var text_factor_code = 0
    for index in range(factor_length):
        text_factor_code = text_factor_code * 4 + Int(text[index])
    let last_factor_start = text_length - factor_length
    for sample_start in range(last_factor_start + 1):
        if sample_start % shift == 0:
            var pattern_position = heads[text_factor_code]
            while pattern_position >= 0:
                let candidate = sample_start - pattern_position
                if candidate >= 0 and candidate + pattern_length <= text_length:
                    var compared = 0
                    while compared < pattern_length and text[candidate + compared] == pattern[compared]:
                        compared += 1
                    if compared == pattern_length:
                        match_count += 1
                        offset_sum += Int64(candidate)
                        offset_xor ^= Int64(candidate)
                pattern_position = next_factor[pattern_position]
        if sample_start < last_factor_start:
            text_factor_code = (text_factor_code - Int(text[sample_start]) * power) * 4 + Int(text[sample_start + factor_length])

    return (match_count << 36) | (offset_sum << 12) | offset_xor
