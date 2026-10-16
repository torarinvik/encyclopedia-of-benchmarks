#[no_mangle]
pub unsafe extern "C" fn longest_consecutive_characters(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 1 || length > 257 { return -1; }
    let count_value = *values;
    if !(1..=256).contains(&count_value) || length != count_value as usize + 1 { return -1; }
    let count = count_value as usize;
    for index in 0..count {
        let value = *values.add(index + 1);
        if !(0..=127).contains(&value) { return -1; }
    }
    if output.is_null() || capacity < 3 { return -2; }

    let mut best_character = *values.add(1);
    let mut best_length = 1usize;
    let mut current_length = 1usize;
    for index in 1..count {
        let current = *values.add(index + 1);
        if current == *values.add(index) {
            current_length += 1;
            if current_length > best_length {
                best_length = current_length;
                best_character = current;
            }
        } else {
            current_length = 1;
        }
    }
    *output = best_character as u8;
    *output.add(1) = best_length as u8;
    *output.add(2) = (best_length >> 8) as u8;
    3
}
