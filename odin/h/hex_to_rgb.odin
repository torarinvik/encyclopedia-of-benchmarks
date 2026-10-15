package hex_to_rgb

import "core:c"

hex_nibble :: proc(value: i64) -> i64 {
    if value >= 48 && value <= 57 do return value - 48
    if value >= 65 && value <= 70 do return value - 65 + 10
    if value >= 97 && value <= 102 do return value - 97 + 10
    return -1
}

@(export)
hex_to_rgb :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 6 do return -1
    packed_rgb: i64 = 0
    for index := 0; index < 6; index += 1 {
        nibble := hex_nibble(input[index])
        if nibble < 0 do return -1
        packed_rgb = (packed_rgb << 4) | nibble
    }
    return packed_rgb
}
