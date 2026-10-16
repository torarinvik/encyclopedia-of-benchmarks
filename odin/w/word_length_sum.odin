package word_length_sum

import "core:c"

@(export)
word_length_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length != 0 && values == nil) do return -1
    total: i64 = 0
    for index := 0; index < int(length); index += 1 {
        if values[index] < 0 || values[index] > 255 do return -1
        if values[index] != 32 do total += 1
    }
    return total
}
