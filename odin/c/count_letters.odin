package count_letters

import "core:c"

lowercase_ascii_letter :: proc(value: i64) -> i64 {
    if value >= 65 && value <= 90 do return value + 32
    return value
}

@(export)
count_letters :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || input[1] < 0 || input[1] > 256 do return -1
    text_length := int(input[1])
    if int(length) != text_length + 2 do return -1
    query := lowercase_ascii_letter(input[0])
    if query < 97 || query > 122 do return -1
    count: i64 = 0
    for index := 0; index < text_length; index += 1 {
        value := input[index + 2]
        if !((value >= 97 && value <= 122) || (value >= 65 && value <= 90)) do return -1
        if lowercase_ascii_letter(value) == query do count += 1
    }
    return count
}
