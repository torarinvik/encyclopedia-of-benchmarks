const MAX_LENGTH: usize = 4096;
const INT32_MIN_VALUE: i64 = i32::MIN as i64;
const INT32_MAX_VALUE: i64 = i32::MAX as i64;

fn is_local_maximum(values: &[i64], index: usize) -> bool {
    if index == 0 {
        return values[0] > values[1];
    }
    if index == values.len() - 1 {
        return values[index] > values[index - 1];
    }
    values[index] > values[index - 1] && values[index] > values[index + 1]
}

fn count_range(values: &[i64], start: usize, end: usize) -> i64 {
    if start == end {
        return if is_local_maximum(values, start) { 1 } else { 0 };
    }
    let middle = (start + end) / 2;
    count_range(values, start, middle) + count_range(values, middle + 1, end)
}

/// Count strict local maxima using the pinned recursive partition.
#[no_mangle]
pub extern "C" fn number_of_local_maximum_points(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_LENGTH {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(INT32_MIN_VALUE..=INT32_MAX_VALUE).contains(&value)) {
        return -1;
    }
    if length == 1 {
        return 0; // Source compares the sole element with undefined.
    }
    count_range(values, 0, length - 1)
}
