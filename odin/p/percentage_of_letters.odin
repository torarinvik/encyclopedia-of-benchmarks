package percentage_of_letters

import "core:c"

lower_ascii :: proc "contextless" (value: i64) -> i64 {
    if value >= 65 && value <= 90 do return value + 32
    return value
}

@(export)
percentage_of_letters :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > 4097 || values == nil do return -1
    target := lower_ascii(values[0])
    if target < 97 || target > 122 do return -1
    text_length := length - 1
    matches := c.size_t(0)
    for index := c.size_t(0); index < text_length; index += 1 {
        value := values[index + 1]
        if value < 0 || value > 127 do return -1
        if lower_ascii(value) == target do matches += 1
    }
    return i64((100 * matches) / text_length)
}
