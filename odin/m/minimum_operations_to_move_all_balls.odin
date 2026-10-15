package min_operations_move_balls

import "core:c"

// Return each box's movement count as a 16-bit little-endian value.
@(export)
minimum_operations_to_move_all_balls :: proc "c" (boxes: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > 256 do return -1
    right_ones := i64(0)
    right_distance := i64(0)
    for index := 0; index < int(length); index += 1 {
        value := boxes[index]
        if value != 0 && value != 1 do return -1
        if value == 1 {
            right_ones += 1
            right_distance += i64(index)
        }
    }
    required_capacity := length * 2
    if output_capacity < required_capacity do return -2
    left_ones := i64(0)
    left_distance := i64(0)
    for index := 0; index < int(length); index += 1 {
        if boxes[index] == 1 {
            right_ones -= 1
            left_ones += 1
        }
        distance := left_distance + right_distance
        output[index * 2] = u8(distance & 255)
        output[index * 2 + 1] = u8((distance >> 8) & 255)
        right_distance -= right_ones
        left_distance += left_ones
    }
    return i64(length)
}
