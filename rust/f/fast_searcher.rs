const MAX_ARRAY_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 67;

fn search_segment(values: &[i64], target: i64, offset: usize) -> i64 {
    let length = values.len();
    if length == 0 { return -1; }
    let first = values[0];
    let last = values[length - 1];
    if target < first || target > last { return -1; }
    if first == last { return if target == first { offset as i64 } else { -1 }; }

    let interpolation = ((length - 1) as i64 * (target - first) / (last - first)) as usize;
    let midpoint = length / 2;
    let left = interpolation.min(midpoint);
    let right = interpolation.max(midpoint);
    let (from, to) = if target < values[left] {
        if left == 0 { return -1; }
        (0, left - 1)
    } else if target < values[right] {
        (left, right - 1)
    } else {
        (right, length - 1)
    };
    if to < from { return -1; }
    search_segment(&values[from..=to], target, offset + from)
}

#[no_mangle]
pub unsafe extern "C" fn fast_searcher(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -2; }
    let count_value = unsafe { *input };
    if count_value < 0 || count_value > MAX_ARRAY_LENGTH as i64 { return -2; }
    let count = count_value as usize;
    if length != count + 2 { return -2; }
    let values = unsafe { std::slice::from_raw_parts(input.add(1), count) };
    for index in 0..count {
        if values[index] < -1000 || values[index] > 1000 { return -2; }
        if index > 0 && values[index - 1] >= values[index] { return -2; }
    }
    let target = unsafe { *input.add(length - 1) };
    if target < -1000 || target > 1000 { return -2; }
    search_segment(values, target, 0)
}
