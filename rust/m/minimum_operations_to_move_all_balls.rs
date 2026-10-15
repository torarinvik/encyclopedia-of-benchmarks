/// Return each box's movement count as a 16-bit little-endian value.
#[no_mangle]
pub unsafe extern "C" fn minimum_operations_to_move_all_balls(boxes: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > 256 || (length != 0 && boxes.is_null()) { return -1; }
    let mut right_ones = 0i64;
    let mut right_distance = 0i64;
    for index in 0..length {
        let value = *boxes.add(index);
        if value != 0 && value != 1 { return -1; }
        if value == 1 {
            right_ones += 1;
            right_distance += index as i64;
        }
    }
    let required_capacity = length * 2;
    if output_capacity < required_capacity { return -2; }
    let mut left_ones = 0i64;
    let mut left_distance = 0i64;
    for index in 0..length {
        if *boxes.add(index) == 1 {
            right_ones -= 1;
            left_ones += 1;
        }
        let distance = left_distance + right_distance;
        output.add(index * 2).write((distance & 255) as u8);
        output.add(index * 2 + 1).write(((distance >> 8) & 255) as u8);
        right_distance -= right_ones;
        left_distance += left_ones;
    }
    length as i64
}
