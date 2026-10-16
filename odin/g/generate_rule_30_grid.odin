package generate_rule_30_grid

import "core:c"

MAX_WIDTH :: 64
MAX_GENERATIONS :: 64

@(export)
generate_rule_30_grid :: proc "contextless" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    width_value := input[0]
    generations_value := input[1]
    if width_value < 1 || width_value > MAX_WIDTH || generations_value < 1 || generations_value > MAX_GENERATIONS do return -1
    width := int(width_value)
    generations := int(generations_value)
    output_count := c.size_t(width * generations)
    if output_capacity < output_count || output == nil do return -2
    current: [MAX_WIDTH]i64 = {}
    next: [MAX_WIDTH]i64 = {}
    current[width / 2] = 1
    for column in 0..<width { output[column] = u8(current[column]) }
    for generation in 1..<generations {
        for column in 0..<width {
            left := if column > 0 do current[column-1] else 0
            right := if column+1 < width do current[column+1] else 0
            pattern := uint(left * 4 + current[column] * 2 + right)
            next[column] = i64((30 >> pattern) & 1)
        }
        for column in 0..<width {
            current[column] = next[column]
            output[generation * width + column] = u8(next[column])
        }
    }
    return i64(output_count)
}
