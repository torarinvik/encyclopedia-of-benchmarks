package mean_threshold

import "core:c"

MAX_DIMENSION :: 32
MAX_PARSEABLE_INPUT_LENGTH :: 1027

@(export)
mean_threshold :: proc "c" (input: [^]i64, length: c.size_t,
                            output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_DIMENSION || input[1] < 1 || input[1] > MAX_DIMENSION do return -1

    width := c.size_t(input[0])
    height := c.size_t(input[1])
    pixel_count := width * height
    if length != pixel_count + 2 do return -1

    sum: i64 = 0
    for index := c.size_t(0); index < pixel_count; index += 1 {
        pixel := input[2 + index]
        if pixel < 0 || pixel > 255 do return -1
        sum += pixel
    }

    mean := sum / i64(pixel_count)
    if output_capacity < pixel_count || output == nil do return -2
    for index := c.size_t(0); index < pixel_count; index += 1 {
        output[index] = 0
        if input[2 + index] > mean do output[index] = 255
    }
    return i64(pixel_count)
}

