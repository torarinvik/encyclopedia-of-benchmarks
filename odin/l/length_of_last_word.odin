package length_of_last_word

import "core:c"

@(export)
length_of_last_word :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 129 do return -1
    if input[0] < 0 || input[0] > 128 || length != c.size_t(input[0]) + 1 do return -1
    index := int(input[0])
    for index > 0 && input[index] == 32 { index -= 1 }
    word_length: i64 = 0
    for index > 0 && input[index] != 32 {
        if input[index] < 0 || input[index] > 255 do return -1
        word_length += 1
        index -= 1
    }
    for i := 1; i < int(length); i += 1 {
        if input[i] < 0 || input[i] > 255 do return -1
    }
    return word_length
}
