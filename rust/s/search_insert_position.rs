/// Return the lower-bound position in a strictly increasing signed 32-bit array.
#[no_mangle]
pub unsafe extern "C" fn search_insert_position(input: *const i64, length: usize) -> i64 {
    if length < 1 || length > 257 || input.is_null() { return -1; }
    let target = *input;
    if target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    for index in 1..length {
        let value = *input.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        if index > 1 && *input.add(index - 1) >= value { return -1; }
    }
    let mut low = 0usize;
    let mut high = length - 1;
    while low < high {
        let middle = low + (high - low) / 2;
        if *input.add(middle + 1) < target { low = middle + 1; }
        else { high = middle; }
    }
    low as i64
}
