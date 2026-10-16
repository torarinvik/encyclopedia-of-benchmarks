/// Count sorted signed 32-bit values less than or equal to the first input value.
#[no_mangle]
pub unsafe extern "C" fn count_less_equal_in_sorted_array(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > 513 { return -1; }
    let key = *input;
    if key < i32::MIN as i64 || key > i32::MAX as i64 { return -1; }
    for index in 1..length {
        let value = *input.add(index);
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        if index > 1 && *input.add(index - 1) > value { return -1; }
    }

    let mut left = 1usize;
    let mut right = length - 1;
    let mut count = 0usize;
    while left <= right {
        let middle = left + (right - left) / 2;
        if *input.add(middle) > key { right = middle - 1; }
        else {
            count = middle;
            left = middle + 1;
        }
    }
    count as i64
}
