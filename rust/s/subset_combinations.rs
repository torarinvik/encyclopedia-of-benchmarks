/// Emit fixed-size index combinations as little-endian subset masks.
#[no_mangle]
pub extern "C" fn subset_combinations(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length == 0 || length > 13 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 0 { return -1; }
    let item_count = length - 1;
    if item_count > 12 { return -1; }
    if input[0] > item_count as i64 { return 0; }
    let choose = input[0] as usize;
    let mut count = 1usize;
    for index in 1..=choose { count = count * (item_count - choose + index) / index; }
    let required = 2 * count;
    if output_capacity < required || output.is_null() { return -2; }
    let mut indices = [0usize; 12];
    for index in 0..choose { indices[index] = index; }
    let bytes = unsafe { std::slice::from_raw_parts_mut(output, required) };
    for combination in 0..count {
        let mut mask = 0usize;
        for &index in &indices[..choose] { mask |= 1usize << index; }
        bytes[2 * combination] = mask as u8;
        bytes[2 * combination + 1] = (mask >> 8) as u8;
        if combination + 1 == count { break; }
        let mut position = choose;
        while position > 0 {
            position -= 1;
            if indices[position] < item_count - choose + position { break; }
        }
        indices[position] += 1;
        for index in position + 1..choose { indices[index] = indices[index - 1] + 1; }
    }
    count as i64
}
