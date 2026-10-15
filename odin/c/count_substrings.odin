package count_substrings

import "core:c"

MAX_LENGTH :: 4096

find_next :: proc "contextless" (values: [^]i64, text_length, pattern_length, pattern_start, start: i64) -> i64 {
    if start > text_length || pattern_length > text_length - start do return -1
    last := text_length - pattern_length
    for position := start; position <= last; position += 1 {
        offset := i64(0)
        for offset < pattern_length && values[2 + position + offset] == values[pattern_start + offset] { offset += 1 }
        if offset == pattern_length do return position
    }
    return -1
}

@(export)
count_substrings :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || values[0] < 0 || values[0] > MAX_LENGTH || values[1] < 0 || values[1] > MAX_LENGTH do return -1
    text_length, pattern_length := values[0], values[1]
    if length != c.size_t(2 + text_length + pattern_length) do return -1
    for i := c.size_t(2); i < length; i += 1 {
        if values[i] < 0 || values[i] > 127 do return -1
    }
    if pattern_length == 0 do return text_length + 1
    pattern_start := 2 + text_length
    count := i64(0)
    position := find_next(values, text_length, pattern_length, pattern_start, 0)
    for position >= 0 {
        count += 1
        position = find_next(values, text_length, pattern_length, pattern_start, position + 1)
    }
    return count
}
