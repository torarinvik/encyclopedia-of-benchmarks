/// Divide-and-conquer maximum nonempty contiguous-subarray sum.
fn max_subarray_range(values: &[i64], start: usize, end: usize) -> i64 {
    if end - start == 1 { return values[start]; }
    let middle = start + (end - start) / 2;
    let left_best = max_subarray_range(values, start, middle);
    let right_best = max_subarray_range(values, middle, end);
    let mut running = values[middle - 1];
    let mut left_suffix = running;
    let mut index = middle - 1;
    while index > start {
        index -= 1;
        running += values[index];
        if running > left_suffix { left_suffix = running; }
    }
    running = values[middle];
    let mut right_prefix = running;
    index = middle + 1;
    while index < end {
        running += values[index];
        if running > right_prefix { right_prefix = running; }
        index += 1;
    }
    let crossing = left_suffix + right_prefix;
    left_best.max(right_best).max(crossing)
}

#[no_mangle]
pub extern "C" fn max_subarray(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 1024 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| value < i32::MIN as i64 || value > i32::MAX as i64) {
        return -1;
    }
    max_subarray_range(values, 0, length)
}
