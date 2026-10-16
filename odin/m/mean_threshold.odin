package mean_threshold

import "core:c"

MAX_SIDE_LENGTH :: 32
MAX_PARSEABLE_INPUT_LENGTH :: 1026

@(export)
mean_threshold :: proc "c" (input: [^]i64, length: c.size_t,
                            output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_SIDE_LENGTH do return -1

    side := c.size_t(input[0])
    pixel_count := side * side
    if length != pixel_count + 1 do return -1

    sum: i64 = 0
    for index := c.size_t(0); index < pixel_count; index += 1 {
        pixel := input[1 + index]
        if pixel < 0 || pixel > 255 do return -1
        sum += pixel
    }

    mean := sum / i64(pixel_count)
    if output_capacity < pixel_count || output == nil do return -2
    for index := c.size_t(0); index < pixel_count; index += 1 {
        output[index] = 0
        if input[1 + index] > mean do output[index] = 255
    }
    return i64(pixel_count)
}

