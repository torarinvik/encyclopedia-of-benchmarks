package charoccurrence

import "core:c"

MAX_INPUT :: 128
MAX_OUTPUT :: 1024

append_decimal :: proc "contextless" (buffer: [^]u8, offset: usize, value: usize) -> usize {
    digits: [3]u8
    count: usize = 0
    remaining := value
    for {
        digits[count] = u8(48 + remaining % 10)
        count += 1
        remaining /= 10
        if remaining == 0 do break
    }
    position := offset
    for count > 0 {
        count -= 1
        buffer[position] = digits[count]
        position += 1
    }
    return position
}

@(export)
charoccurrence :: proc "c" (values: [^]i64, length: c.size_t,
                             output: [^]u8, capacity: c.size_t) -> i64 {
    if length > MAX_INPUT do return -1
    if length > 0 && values == nil do return -1
    counts: [128]i64
    for index := 0; index < int(length); index += 1 {
        if values[index] < 0 || values[index] > 127 do return -1
        counts[int(values[index])] += 1
    }
    encoded: [MAX_OUTPUT]u8
    used: usize = 0
    for codepoint := 0; codepoint < 128; codepoint += 1 {
        count := counts[codepoint]
        if count == 0 do continue
        if used > 0 {
            encoded[used] = u8(',')
            used += 1
        }
        used = append_decimal(&encoded[0], used, usize(codepoint))
        encoded[used] = u8('=')
        used += 1
        used = append_decimal(&encoded[0], used, usize(count))
    }
    if used > capacity do return -2
    if used > 0 && output == nil do return -2
    for index: usize = 0; index < used; index += 1 {
        output[index] = encoded[index]
    }
    return i64(used)
}
