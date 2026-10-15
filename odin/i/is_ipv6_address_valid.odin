package is_ipv6_address_valid

import "core:c"

MAX_INPUT_LENGTH :: 256

is_hex_digit :: proc(value: i64) -> bool {
    return (value >= 48 && value <= 57) || (value >= 97 && value <= 102) || (value >= 65 && value <= 70)
}

valid_ipv6_text :: proc(input: [^]i64, text_length: int) -> bool {
    if text_length == 0 do return false
    groups, group_length, compression_count := 0, 0, 0
    in_group := false
    index := 0
    for index < text_length {
        value := input[index + 1]
        if value == 58 {
            if index + 1 < text_length && input[index + 2] == 58 {
                if (index > 0 && input[index] == 58) ||
                    (index + 2 < text_length && input[index + 3] == 58) || compression_count != 0 do return false
                if in_group {
                    groups += 1
                    in_group = false
                    group_length = 0
                } else if index != 0 {
                    return false
                }
                compression_count += 1
                index += 2
                continue
            }
            if index == 0 || index + 1 == text_length || !in_group do return false
            groups += 1
            in_group = false
            group_length = 0
            index += 1
            continue
        }
        if !is_hex_digit(value) || group_length == 4 do return false
        group_length += 1
        in_group = true
        index += 1
    }
    if in_group do groups += 1
    if compression_count == 0 do return groups == 8
    return groups < 8
}

@(export)
is_ipv6_address_valid :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 do return -1
    if input[0] < 0 || input[0] > MAX_INPUT_LENGTH do return -1
    text_length := int(input[0])
    if int(length) != text_length + 1 do return -1
    for index := 0; index < text_length; index += 1 {
        if input[index + 1] < 0 || input[index + 1] > 127 do return -1
    }
    if valid_ipv6_text(input, text_length) do return 1
    return 0
}
