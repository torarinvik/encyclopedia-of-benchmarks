package erosion_operation
import "core:c"

@(export)
erosion_operation :: proc "c"(input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 38 do return -1
    height, width := input[0], input[1]
    if height < 1 || height > 6 || width < 1 || width > 6 || length != c.size_t(2 + height * width) do return -1
    for i := c.size_t(2); i < length; i += 1 {
        if input[i] != 0 && input[i] != 1 do return -1
    }
    result: i64 = 0
    for row := i64(1); row + 1 < height; row += 1 {
        for col := i64(1); col + 1 < width; col += 1 {
            at := 2 + row * width + col
            if input[at] == 1 && input[at-width] == 1 && input[at+width] == 1 && input[at-1] == 1 && input[at+1] == 1 {
                result |= i64(1) << (row * width + col)
            }
        }
    }
    return result
}
