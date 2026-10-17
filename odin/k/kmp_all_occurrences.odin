package kmp_all_occurrences

import "core:c"

MAX_TEXT_LENGTH :: 256
MAX_PATTERN_LENGTH :: 64
MAX_INPUT_LENGTH :: 322

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte: int = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits >> u64(8 * byte))
    }
}

@(export)
kmp_all_occurrences :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    text_length_value := values[0]
    pattern_length_value := values[1]
    if text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH ||
        pattern_length_value < 1 || pattern_length_value > MAX_PATTERN_LENGTH do return -1
    text_length := int(text_length_value)
    pattern_length := int(pattern_length_value)
    if length != c.size_t(2 + text_length + pattern_length) do return -1
    for i in 0..<text_length + pattern_length {
        value := values[2 + i]
        if value < 0 || value > 127 do return -1
    }

    prefix: [MAX_PATTERN_LENGTH]int = {}
    for i := 1; i < pattern_length; i += 1 {
        matched := prefix[i - 1]
        for matched > 0 && values[2 + text_length + i] != values[2 + text_length + matched] {
            matched = prefix[matched - 1]
        }
        if values[2 + text_length + i] == values[2 + text_length + matched] do matched += 1
        prefix[i] = matched
    }

    matches: [MAX_TEXT_LENGTH]int = {}
    match_count := 0
    matched := 0
    for i := 0; i < text_length; i += 1 {
        for matched > 0 && values[2 + i] != values[2 + text_length + matched] {
            matched = prefix[matched - 1]
        }
        if values[2 + i] == values[2 + text_length + matched] do matched += 1
        if matched == pattern_length {
            matches[match_count] = i + 1 - pattern_length
            match_count += 1
            matched = prefix[matched - 1]
        }
    }

    output_bytes := match_count * 8
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2
    for i := 0; i < match_count; i += 1 {
        put_i64_le(output, i * 8, i64(matches[i]))
    }
    return i64(output_bytes)
}
