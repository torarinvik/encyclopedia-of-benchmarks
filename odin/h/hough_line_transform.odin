package hough_line_transform

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 67
RHO_COUNT :: 29
OUTPUT_BYTES :: 116

@(export)
hough_line_transform :: proc "contextless" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
    height_value := input[0]
    width_value := input[1]
    if height_value < 1 || height_value > 8 || width_value < 1 || width_value > 8 do return -1
    height := int(height_value)
    width := int(width_value)
    cells := height * width
    if length != c.size_t(2 + cells) do return -1
    for index := 0; index < cells; index += 1 {
        if input[index + 2] != 0 && input[index + 2] != 1 do return -1
    }
    if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2

    accumulator: [OUTPUT_BYTES]u8
    for index := 0; index < OUTPUT_BYTES; index += 1 { accumulator[index] = 0 }
    for row := 0; row < height; row += 1 {
        for column := 0; column < width; column += 1 {
            if input[2 + row * width + column] == 0 do continue
            x := i64(column)
            y := i64(row)
            rho := [4]i64{x, x + y, y, -x + y}
            for angle := 0; angle < 4; angle += 1 {
                bin := angle * RHO_COUNT + int(rho[angle] + 14)
                accumulator[bin] += 1
            }
        }
    }
    for index := 0; index < OUTPUT_BYTES; index += 1 { output[index] = accumulator[index] }
    return i64(OUTPUT_BYTES)
}
