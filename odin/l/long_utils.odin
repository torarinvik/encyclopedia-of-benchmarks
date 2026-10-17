package long_utils

import "core:c"

@(export, link_name="long_utils")
long_utils :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 3 do return -1
    if input[0] < 0 || input[0] > 3 || input[2] < 0 || input[2] > 63 do return -1
    if output == nil || capacity < 8 do return -2
    bits := transmute(u64)(input[1])
    distance := u32(input[2])
    rotated := bits
    if distance != 0 {
        if input[0] < 2 do rotated = (bits << distance) | (bits >> (64 - distance))
        else rotated = (bits >> distance) | (bits << (64 - distance))
    }
    for byte := 0; byte < 8; byte += 1 {
        output[byte] = u8((rotated >> (8 * byte)) & 255)
    }
    return 8
}
