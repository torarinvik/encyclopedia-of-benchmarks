package flood_fill

import "core:c"

MAX_SIDE :: 32
MAX_CELLS :: MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH :: 6 + MAX_CELLS

put_i64 :: proc "contextless" (output: [^]u8, index: c.size_t, value: i64) {
    bits := u64(value)
    for byte := c.size_t(0); byte < 8; byte += 1 { output[index * 8 + byte] = u8(bits >> (byte * 8)) }
}

@(export)
flood_fill :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 6 || length > MAX_INPUT_LENGTH do return -1
    width_value := input[0]; height_value := input[1]
    start_x_value := input[2]; start_y_value := input[3]
    new_color := input[4]; target_color := input[5]
    if width_value < 1 || width_value > MAX_SIDE || height_value < 1 || height_value > MAX_SIDE do return -1
    if new_color < -2147483648 || new_color > 2147483647 || target_color < -2147483648 || target_color > 2147483647 || new_color == target_color do return -1
    width := int(width_value); height := int(height_value)
    if length != c.size_t(6 + width * height) || start_x_value < 0 || start_x_value >= width_value || start_y_value < 0 || start_y_value >= height_value do return -1
    cells := width * height
    image: [MAX_CELLS]i64
    for index := 0; index < cells; index += 1 {
        image[index] = input[6 + index]
        if image[index] < -2147483648 || image[index] > 2147483647 do return -1
    }
    start := int(start_x_value) * height + int(start_y_value)
    if image[start] == target_color {
        stack: [MAX_CELLS]int
        top := 0
        image[start] = new_color
        stack[top] = start
        top += 1
        for top > 0 {
            top -= 1
            index := stack[top]
            x := index / height; y := index % height
            for dx := -1; dx <= 1; dx += 1 {
                for dy := -1; dy <= 1; dy += 1 {
                    if dx == 0 && dy == 0 do continue
                    next_x := x + dx; next_y := y + dy
                    if next_x < 0 || next_x >= width || next_y < 0 || next_y >= height do continue
                    next := next_x * height + next_y
                    if image[next] == target_color {
                        image[next] = new_color
                        stack[top] = next
                        top += 1
                    }
                }
            }
        }
    }
    required := c.size_t(cells * 8)
    if output == nil || capacity < required do return -2
    for index := 0; index < cells; index += 1 { put_i64(output, c.size_t(index), image[index]) }
    return i64(required)
}
