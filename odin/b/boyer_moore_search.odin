package boyer_moore_search

import "core:c"

// Return the first ASCII byte match using the bad-character rule.
@(export)
boyer_moore_search :: proc "c" (input_values: [^]i64, length: c.size_t) -> i64 {
    if input_values == nil || length < 2 || length > 8194 do return -1
    if input_values[0] < 0 || input_values[0] > 4096 || input_values[1] < 0 || input_values[1] > 4096 do return -1
    text_length := c.size_t(input_values[0])
    pattern_length := c.size_t(input_values[1])
    if length != 2 + text_length + pattern_length do return -1
    for index := c.size_t(0); index < text_length + pattern_length; index += 1 {
        if input_values[2 + index] < 0 || input_values[2 + index] > 127 do return -1
    }
    if pattern_length == 0 do return 0
    if pattern_length > text_length do return -1

    pattern_start := 2 + text_length
    last_occurrence: [128]i64
    for value := 0; value < 128; value += 1 { last_occurrence[value] = -1 }
    for index := c.size_t(0); index < pattern_length; index += 1 {
        last_occurrence[int(input_values[pattern_start + index])] = i64(index)
    }

    alignment := c.size_t(0)
    for alignment <= text_length - pattern_length {
        pattern_index := pattern_length
        for pattern_index > 0 && input_values[pattern_start + pattern_index - 1] == input_values[2 + alignment + pattern_index - 1] {
            pattern_index -= 1
        }
        if pattern_index == 0 do return i64(alignment)
        text_byte := int(input_values[2 + alignment + pattern_index - 1])
        shift := i64(pattern_index - 1) - last_occurrence[text_byte]
        if shift < 1 do shift = 1
        alignment += c.size_t(shift)
    }
    return -1
}
