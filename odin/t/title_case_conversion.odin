package title_case_conversion

import "core:c"

@(export)
title_case_conversion :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 do return -1
    if input[0] < 0 || input[0] > 256 do return -1
    n := int(input[0])
    if length != c.size_t(n + 1) do return -1
    for index := 0; index < n; index += 1 {
        value := input[index + 1]
        is_letter := (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')
        if is_letter do continue
        if value == ' ' && index > 0 && index + 1 < n && input[index] != ' ' do continue
        return -1
    }
    if output == nil || output_capacity < c.size_t(n + 1) do return -2
    at_word_start := true
    for index := 0; index < n; index += 1 {
        value := input[index + 1]
        if value == ' ' {
            output[index] = u8(value)
            at_word_start = true
        } else if at_word_start {
            if value >= 'a' && value <= 'z' do value -= 'a' - 'A'
            output[index] = u8(value)
            at_word_start = false
        } else {
            if value >= 'A' && value <= 'Z' do value += 'a' - 'A'
            output[index] = u8(value)
        }
    }
    output[n] = 0
    return i64(n)
}
