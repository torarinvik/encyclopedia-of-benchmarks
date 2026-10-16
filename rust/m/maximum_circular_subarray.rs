/// Kadane-based maximum nonempty contiguous circular-subarray sum.
const MAX_INPUT_LENGTH: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn maximum_circular_subarray(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT_LENGTH { return i64::MIN; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(-1_000_000..=1_000_000).contains(&value)) { return i64::MIN; }

    let mut total = values[0];
    let mut current_max = values[0];
    let mut max_so_far = values[0];
    let mut current_min = values[0];
    let mut min_so_far = values[0];
    for &value in &values[1..] {
        current_max = (current_max + value).max(value);
        max_so_far = max_so_far.max(current_max);
        current_min = (current_min + value).min(value);
        min_so_far = min_so_far.min(current_min);
        total += value;
    }
    if min_so_far == total { return max_so_far; }
    max_so_far.max(total - min_so_far)
}
