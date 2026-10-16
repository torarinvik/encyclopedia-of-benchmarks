fn upper_bound_range(values: &[i64], target: i64, left: i64, right: i64) -> i64 {
    if right <= left { return left; }
    let middle = (left + right) / 2;
    if target < values[middle as usize] {
        upper_bound_range(values, target, left, middle)
    } else {
        upper_bound_range(values, target, middle + 1, right)
    }
}

#[no_mangle]
pub extern "C" fn upper_bound(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 513 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(values, length) };
    let target = packed[0];
    if target < i32::MIN as i64 || target > i32::MAX as i64 { return -1; }
    let array = &packed[1..];
    for (index, &value) in array.iter().enumerate() {
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        if index > 0 && array[index - 1] > value { return -1; }
    }
    upper_bound_range(array, target, 0, array.len() as i64 - 1)
}
