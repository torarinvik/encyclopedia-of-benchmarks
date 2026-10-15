fn lower_bound_range(values: &[i64], target: i64, left: i64, right: i64) -> i64 {
    if right <= left { return left; }
    let middle = (left + right) / 2;
    if target == values[middle as usize] { return middle; }
    if target < values[middle as usize] {
        lower_bound_range(values, target, left, middle)
    } else {
        lower_bound_range(values, target, middle + 1, right)
    }
}

#[no_mangle]
pub extern "C" fn lower_bound(values: *const i64, length: usize, target: i64) -> i64 {
    if length > 512 || target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    if length > 0 && values.is_null() { return -1; }
    let slice: &[i64] = if length == 0 { &[] } else {
        // The C caller supplies a valid allocation when length is nonzero.
        unsafe { std::slice::from_raw_parts(values, length) }
    };
    for (i, &value) in slice.iter().enumerate() {
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        if i > 0 && slice[i - 1] > value { return -1; }
    }
    lower_bound_range(slice, target, 0, length as i64 - 1)
}
