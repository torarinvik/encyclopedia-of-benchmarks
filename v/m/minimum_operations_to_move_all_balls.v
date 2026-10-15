module min_operations_move_balls

// Return each box's movement count as a 16-bit little-endian value.
@[export: 'minimum_operations_to_move_all_balls']
pub fn minimum_operations_to_move_all_balls(boxes &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 256 { return -1 }
    if length == 0 { return 0 }
    unsafe {
        mut right_ones := i64(0)
        mut right_distance := i64(0)
        for index in 0 .. length {
            value := boxes[index]
            if value != 0 && value != 1 { return -1 }
            if value == 1 {
                right_ones++
                right_distance += i64(index)
            }
        }
        required_capacity := length * 2
        if output_capacity < required_capacity { return -2 }
        mut left_ones := i64(0)
        mut left_distance := i64(0)
        for index in 0 .. length {
            if boxes[index] == 1 {
                right_ones--
                left_ones++
            }
            distance := left_distance + right_distance
            output[index * 2] = u8(distance & 255)
            output[index * 2 + 1] = u8((distance >> 8) & 255)
            right_distance -= right_ones
            left_distance += left_ones
        }
        return i64(length)
    }
}
