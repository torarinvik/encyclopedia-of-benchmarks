/// Binary search over a monotone sequence in either direction.
#[no_mangle]
pub unsafe extern "C" fn order_agnostic_binary_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > 100_001 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    let target = values[0];
    let count = values[1];
    if target < i32::MIN as i64 || target > i32::MAX as i64 || !(1..=99_999).contains(&count)
        || length != count as usize + 2
    {
        return -1;
    }
    let count = count as usize;
    let ascending = values[2] < values[count + 1];
    let (mut start, mut right) = (0i64, count as i64 - 1);
    while start <= right {
        let middle = start + (right - start) / 2;
        let value = values[middle as usize + 2];
        if value == target {
            return middle;
        }
        if ascending {
            if value < target { start = middle + 1; }
            else { right = middle - 1; }
        } else if value > target {
            start = middle + 1;
        } else {
            right = middle - 1;
        }
    }
    -1
}
